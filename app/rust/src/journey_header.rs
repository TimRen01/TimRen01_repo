use anyhow::Result;
use chrono::{DateTime, NaiveDate, Utc};
use flutter_rust_bridge::frb;
use protobuf::EnumOrUnknown;
use strum_macros::EnumIter;

use crate::{protos, utils};

#[derive(Copy, Clone, Debug, EnumIter, PartialEq, Eq, Hash)]
#[repr(i8)]
pub enum JourneyType {
    Vector = 0,
    Bitmap = 1,
}

impl JourneyType {
    pub fn to_int(&self) -> i8 {
        *self as i8
    }

    pub fn of_int(i: i8) -> Result<Self> {
        match i {
            0 => Ok(JourneyType::Vector),
            1 => Ok(JourneyType::Bitmap),
            _ => bail!("Invalid int for `JourneyType` {}", i),
        }
    }

    pub fn to_proto(self) -> protos::journey::header::Type {
        use protos::journey::header::Type;
        match self {
            JourneyType::Vector => Type::VECTOR,
            JourneyType::Bitmap => Type::BITMAP,
        }
    }

    pub fn of_proto(proto: protos::journey::header::Type) -> Self {
        use protos::journey::header::Type;
        match proto {
            Type::VECTOR => JourneyType::Vector,
            Type::BITMAP => JourneyType::Bitmap,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::JourneyType;
    use strum::IntoEnumIterator;

    #[test]
    fn int_conversion() {
        for type_ in JourneyType::iter() {
            assert_eq!(
                type_,
                JourneyType::of_int(JourneyType::to_int(&type_)).unwrap()
            )
        }
    }
}

#[derive(Eq, Hash, Clone, Copy, Debug, PartialEq)]
pub enum JourneyKind {
    DefaultKind,
    Flight,
}

impl JourneyKind {
    pub fn to_proto(self) -> protos::journey::header::Kind {
        use protos::journey::header::{kind, Kind};
        let mut kind = Kind::new();
        match self {
            JourneyKind::DefaultKind => kind.set_build_in(kind::BuiltIn::DEFAULT),
            JourneyKind::Flight => kind.set_build_in(kind::BuiltIn::FLIGHT),
        };
        kind
    }

    pub fn of_proto(proto: protos::journey::header::Kind) -> Self {
        use protos::journey::header::kind;
        if proto.has_custom_kind() {
            let custom_kind = proto.custom_kind();
            panic!("custom journkey kind is not supported, custom_kind = {custom_kind}")
        }
        match proto.build_in() {
            kind::BuiltIn::DEFAULT => JourneyKind::DefaultKind,
            kind::BuiltIn::FLIGHT => JourneyKind::Flight,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
#[frb(non_opaque)]
pub struct JourneyHeader {
    pub id: String,
    pub revision: String,
    pub journey_date: NaiveDate,
    pub created_at: DateTime<Utc>,
    pub updated_at: Option<DateTime<Utc>>,
    pub start: Option<DateTime<Utc>>,
    pub end: Option<DateTime<Utc>>,
    pub journey_type: JourneyType,
    pub journey_kind: JourneyKind,
    pub note: Option<String>,
    pub postprocessor_algo: Option<String>,
}

impl JourneyHeader {
    pub fn of_proto(mut proto: protos::journey::Header) -> Result<Self> {
        let journey_type = proto
            .type_
            .enum_value()
            .map_err(|x| anyhow!("Unknown proto journey type: {}", x))?;
        Ok(JourneyHeader {
            id: proto.id,
            revision: proto.revision,
            journey_date: utils::date_of_days_since_epoch(proto.journey_date__days_since_epoch),
            created_at: DateTime::from_timestamp(proto.created_at__timestamp_sec, 0).unwrap(),
            updated_at: proto
                .updated_at__timestamp_sec
                .and_then(|sec| DateTime::from_timestamp(sec, 0)),
            end: proto
                .end__timestamp_sec
                .and_then(|sec| DateTime::from_timestamp(sec, 0)),
            start: proto
                .start__timestamp_sec
                .and_then(|sec| DateTime::from_timestamp(sec, 0)),
            journey_type: JourneyType::of_proto(journey_type),
            journey_kind: JourneyKind::of_proto(match proto.kind.take() {
                None => bail!("Missing `kind`"),
                Some(kind) => kind,
            }),
            note: proto.note,
            postprocessor_algo: proto.postprocessor_algo,
        })
    }

    pub fn to_proto(self) -> protos::journey::Header {
        let JourneyHeader {
            id,
            revision,
            journey_date,
            created_at,
            updated_at,
            start,
            end,
            journey_type,
            journey_kind,
            note,
            postprocessor_algo,
        } = self;
        let mut proto = protos::journey::Header::new();
        proto.id = id;
        proto.revision = revision;
        proto.journey_date__days_since_epoch = utils::date_to_days_since_epoch(journey_date);
        proto.created_at__timestamp_sec = created_at.timestamp();
        proto.updated_at__timestamp_sec = updated_at.map(|x| x.timestamp());
        proto.end__timestamp_sec = end.map(|x| x.timestamp());
        proto.start__timestamp_sec = start.map(|x| x.timestamp());
        proto.type_ = EnumOrUnknown::new(journey_type.to_proto());
        proto.kind.0 = Some(Box::new(journey_kind.to_proto()));
        proto.note = note;
        proto.postprocessor_algo = postprocessor_algo;
        proto
    }
}

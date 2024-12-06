pub mod test_utils;

use memolanes_core::{import_data, journey_area_utils};
/*
#[macro_use]
extern crate assert_float_eq;
#[test]
fn test_compute_journey_bitmap_area() {
    let (bitmap_import, _warnings) =
        import_data::load_fow_sync_data("./tests/data/fow_1.zip").unwrap();
    /* area unit: m^2 */
    let calculated_area = journey_area_utils::compute_journey_bitmap_area(&bitmap_import);
    assert_f64_near!(calculated_area, 3035669.991974149);
}
*/

fn approximate_equal(a: f64, b: f64, tolerance: f64) -> bool {
    (a - b).abs() <= tolerance
}

#[test]
fn test_get_area_by_journey_bitmap_interation_bit() {
    let (bitmap_import, _warnings) =
        import_data::load_fow_sync_data("./tests/data/fow_1.zip").unwrap();
    /* test_get_area_by_journey_bitmap_interation_bit result as expected */
    let expected_area = 3035667.3046264146;
    let calculated_area =
        journey_area_utils::get_area_by_journey_bitmap_interation_bit(&bitmap_import);
    let tolerance = 1e4;
    let difference = (calculated_area - expected_area).abs();
    dbg!(calculated_area, expected_area, tolerance, difference);
    assert!(
        approximate_equal(calculated_area, expected_area, tolerance),
        "result area {} is not approximately equal to expected area {} ",
        calculated_area,
        expected_area
    );
}

#[test]
fn test_get_area_by_journey_bitmap_interation_bit_width_only() {
    let (bitmap_import, _warnings) =
        import_data::load_fow_sync_data("./tests/data/fow_1.zip").unwrap();
    /* 43.412037048499996 km^2 */
    let expected_area = 3035667.3046264146;
    let calculated_area =
        journey_area_utils::get_area_by_journey_bitmap_interation_bit_width_only(&bitmap_import);
    let tolerance = 1e4;
    let difference = (calculated_area - expected_area).abs();
    dbg!(calculated_area, expected_area, tolerance, difference);
    assert!(
        approximate_equal(calculated_area, expected_area, tolerance),
        "result area {} is not approximately equal to expected area {} ",
        calculated_area,
        expected_area
    );
}

#[test]
fn test_get_area_by_journey_bitmap_interation_bit_height_only() {
    let (bitmap_import, _warnings) =
        import_data::load_fow_sync_data("./tests/data/fow_1.zip").unwrap();
    /* 43.412037048499996 km^2 */
    let expected_area = 3035667.3046264146;
    let calculated_area =
        journey_area_utils::get_area_by_journey_bitmap_interation_bit_height_only(&bitmap_import);
    let tolerance = 1e4;
    let difference = (calculated_area - expected_area).abs();
    dbg!(calculated_area, expected_area, tolerance, difference);
    assert!(
        approximate_equal(calculated_area, expected_area, tolerance),
        "result area {} is not approximately equal to expected area {} ",
        calculated_area,
        expected_area
    );
}

#[test]
fn test_get_area_by_journey_bitmap_interation_bit_estimate_block() {
    let (bitmap_import, _warnings) =
        import_data::load_fow_sync_data("./tests/data/fow_1.zip").unwrap();
    /* 43.412037048499996 km^2 */
    let expected_area = 3035667.3046264146;
    let calculated_area =
        journey_area_utils::get_area_by_journey_bitmap_interation_bit_estimate_block(
            &bitmap_import,
        );
    let tolerance = 1e4;
    let difference = (calculated_area - expected_area).abs();
    dbg!(calculated_area, expected_area, tolerance, difference);
    assert!(
        approximate_equal(calculated_area, expected_area, tolerance),
        "result area {} is not approximately equal to expected area {} ",
        calculated_area,
        expected_area
    );
}

#[test]
fn test_get_area_by_journey_bitmap_interation_block() {
    let (bitmap_import, _warnings) =
        import_data::load_fow_sync_data("./tests/data/fow_1.zip").unwrap();
    /* 43.412037048499996 km^2 */
    let expected_area = 3035667.3046264146;
    let calculated_area =
        journey_area_utils::get_area_by_journey_bitmap_interation_block(&bitmap_import);
    let tolerance = 1e4;
    let difference = (calculated_area - expected_area).abs();
    dbg!(calculated_area, expected_area, tolerance, difference);
    assert!(
        approximate_equal(calculated_area, expected_area, tolerance),
        "result area {} is not approximately equal to expected area {} ",
        calculated_area,
        expected_area
    );
}

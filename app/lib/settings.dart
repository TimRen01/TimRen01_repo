import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memolanes/gps_manager.dart';
import 'package:memolanes/preferences_manager.dart';
import 'package:memolanes/src/rust/api/api.dart' as api;
import 'package:memolanes/utils.dart';
import 'package:memolanes/raw_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'import_data.dart';

class SettingsBody extends StatefulWidget {
  const SettingsBody({super.key});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  bool _isUnexpectedExitNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  _launchUrl(String updateUrl) async {
    final url = Uri.parse(updateUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $updateUrl';
    }
  }

  Future<void> _selectImportFile(
    BuildContext context,
    ImportType importType,
  ) async {
    // TODO: FilePicker is weird and `allowedExtensions` does not really work.
    // https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ
    // List<String> allowedExtensions;
    // if (importType == ImportType.fow) {
    //   allowedExtensions = ['zip'];
    // } else {
    //   allowedExtensions = ['kml', 'gpx'];
    // }
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    if (path != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ImportDataPage(path: path, importType: importType);
          },
        ),
      );
    }
  }

  Future<void> _loadNotificationStatus() async {
    final status =
        await PreferencesManager.getUnexpectedExitNotificationStatus();
    setState(() {
      _isUnexpectedExitNotificationEnabled = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    var updateUrl = context.watch<UpdateNotifier>().updateUrl;
    var gpsManager = context.watch<GpsManager>();

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () async {
              _selectImportFile(context, ImportType.gpxOrKml);
            },
            child: Text(context.tr("journey.import_kml_gpx_data")),
          ),
          ElevatedButton(
            onPressed: () async {
              await showCommonDialog(
                context,
                context.tr("import_fow_data.description_md"),
                markdown: true,
              );

              if (await api.containsBitmapJourney()) {
                if (!context.mounted) return;
                await showCommonDialog(
                  context,
                  context.tr(
                    "import_fow_data.warning_for_import_multiple_data_md",
                  ),
                  markdown: true,
                );
              }

              if (!context.mounted) return;
              await _selectImportFile(context, ImportType.fow);
            },
            child: Text(context.tr("import_fow_data.button")),
          ),
          ElevatedButton(
            onPressed: () async {
              if (gpsManager.recordingStatus != GpsRecordingStatus.none) {
                await showCommonDialog(
                  context,
                  "Please stop the current ongoing journey before archiving.",
                );
                return;
              }
              var tmpDir = await getTemporaryDirectory();
              var ts = DateTime.now().millisecondsSinceEpoch;
              var filepath = "${tmpDir.path}/${ts.toString()}.mldx";
              if (!context.mounted) return;
              await showLoadingDialog(
                context: context,
                asyncTask: api.generateFullArchive(targetFilepath: filepath),
              );
              if (!context.mounted) return;
              await showCommonExport(context, filepath, deleteFile: true);
            },
            child: Text(context.tr("journey.archive_all_as_mldx")),
          ),
          ElevatedButton(
            onPressed: () async {
              if (gpsManager.recordingStatus != GpsRecordingStatus.none) {
                await showCommonDialog(
                  context,
                  "Please stop the current ongoing journey before deleting all journeys.",
                );
                return;
              }
              if (!await showCommonDialog(
                context,
                "This will delete all journeys in this app. Are you sure?",
                hasCancel: true,
                title: context.tr("journey.delete_journey_title"),
                confirmButtonText: context.tr("journey.delete"),
                confirmGroundColor: Colors.red,
                confirmTextColor: Colors.white,
              )) {
                return;
              }
              try {
                await api.deleteAllJourneys();
                if (context.mounted) {
                  await showCommonDialog(context, "All journeys are deleted.");
                }
              } catch (e) {
                if (context.mounted) {
                  await showCommonDialog(context, e.toString());
                }
              }
            },
            child: Text(context.tr("journey.delete_all")),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: FilePicker is weird and `allowedExtensions` does not really work.
              // https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ
              var result = await FilePicker.platform.pickFiles(
                type: FileType.any,
              );
              if (!context.mounted) return;
              if (result != null) {
                var path = result.files.single.path;
                if (path != null) {
                  try {
                    await showLoadingDialog(
                      context: context,
                      asyncTask: api.importArchive(mldxFilePath: path),
                    );
                    if (context.mounted) {
                      await showCommonDialog(
                        context,
                        "Import succeeded!",
                        title: "Success",
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      await showCommonDialog(context, e.toString());
                    }
                  }
                }
              }
            },
            child: Text(context.tr("journey.import_mldx")),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!await api.mainDbRequireOptimization()) {
                if (!context.mounted) return;
                await showCommonDialog(
                  context,
                  context.tr("db_optimization.already_optimized"),
                );
              } else {
                if (!context.mounted) return;
                if (await showCommonDialog(
                  context,
                  context.tr("db_optimization.confirm"),
                  hasCancel: true,
                )) {
                  if (!context.mounted) return;
                  await showLoadingDialog(
                    context: context,
                    asyncTask: api.optimizeMainDb(),
                  );
                  if (!context.mounted) return;
                  await showCommonDialog(
                    context,
                    context.tr("db_optimization.finsih"),
                  );
                }
              }
            },
            child: Text(context.tr("db_optimization.button")),
          ),
          ElevatedButton(
            onPressed: () async {
              var tmpDir = await getTemporaryDirectory();
              var ts = DateTime.now().millisecondsSinceEpoch;
              var filepath = "${tmpDir.path}/${ts.toString()}.zip";
              await api.exportLogs(targetFilePath: filepath);
              if (!context.mounted) return;
              await showCommonExport(context, filepath, deleteFile: true);
            },
            child: Text(context.tr("advance_settings.export_logs")),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return RawDataPage();
                  },
                ),
              );
            },
            child: Text(context.tr("advance_settings.raw_data_mode")),
          ),
          ElevatedButton(
            onPressed: () async {
              await showLoadingDialog(
                context: context,
                asyncTask: api.rebuildCache(),
              );
            },
            child: Text(context.tr("advance_settings.rebuild_cache")),
          ),
          Row(
            children: [
              Text(context.tr("unexpected_exit_notification.setting_title")),
              Spacer(),
              Switch(
                value: _isUnexpectedExitNotificationEnabled,
                onChanged: (value) async {
                  final status = await Permission.notification.status;
                  if (value) {
                    if (!status.isGranted) {
                      setState(() {
                        _isUnexpectedExitNotificationEnabled = false;
                      });

                      if (!context.mounted) return;
                      await showCommonDialog(
                        context,
                        context.tr(
                            "unexpected_exit_notification.notification_permission_denied"),
                      );
                      Geolocator.openAppSettings();
                      return;
                    }
                  }
                  await PreferencesManager.setUnexpectedExitNotificationStatus(
                      value);
                  setState(() {
                    _isUnexpectedExitNotificationEnabled = value;
                  });
                  if (gpsManager.recordingStatus ==
                      GpsRecordingStatus.recording) {
                    if (!context.mounted) return;
                    await showCommonDialog(
                        context,
                        context.tr(
                          "unexpected_exit_notification.change_affect_next_time",
                        ));
                  }
                },
              ),
            ],
          ),
          if (updateUrl != null) ...[
            ElevatedButton(
              onPressed: () async {
                _launchUrl(updateUrl);
              },
              child: const Text("Update", style: TextStyle(color: Colors.red)),
            ),
          ],
          Center(
            child: Text(
              "Version: ${api.shortCommitHash()}",
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
                fontStyle: FontStyle.normal,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          // TODO: Indicate that we used `MiSans` in this app.
        ],
      ),
    );
  }
}

class UpdateNotifier extends ChangeNotifier {
  String? updateUrl;

  void setUpdateUrl(String? url) {
    updateUrl = url;
    notifyListeners();
  }

  bool hasUpdateNotification() {
    return updateUrl != null;
  }
}

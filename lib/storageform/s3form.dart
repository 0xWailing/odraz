import 'package:flutter/material.dart';
import 'package:img_syncer/design_tokens.dart';
import 'package:img_syncer/event_bus.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/proto/img_syncer.pbgrpc.dart';
import 'package:img_syncer/state_model.dart';
import 'package:img_syncer/storage/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Path-style addressing is off for AWS S3 and on for every other endpoint
/// (Backblaze B2, MinIO, ...).
bool defaultPathStyleFor(String endpoint) =>
    !endpoint.toLowerCase().contains('amazonaws.com');

class S3Form extends StatefulWidget {
  const S3Form({Key? key}) : super(key: key);

  @override
  S3FormState createState() => S3FormState();
}

class S3FormState extends State<S3Form> {
  final _endpoint = TextEditingController();
  final _region = TextEditingController();
  final _bucket = TextEditingController();
  final _accessKey = TextEditingController();
  final _secretKey = TextEditingController();
  final _rootPrefix = TextEditingController();
  bool useSsl = true;
  bool pathStyle = true;
  bool pathStyleTouched = false;
  bool testSuccess = false;
  bool testing = false;
  String? errormsg;

  @override
  void initState() {
    super.initState();
    _endpoint.addListener(_onEndpointChanged);
    for (final c in [_region, _bucket, _accessKey, _secretKey, _rootPrefix]) {
      c.addListener(_invalidateTest);
    }
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      _endpoint.text = prefs.getString('s3_endpoint') ?? '';
      _region.text = prefs.getString('s3_region') ?? '';
      _bucket.text = prefs.getString('s3_bucket') ?? '';
      _accessKey.text = prefs.getString('s3_access_key') ?? '';
      _secretKey.text = prefs.getString('s3_secret_key') ?? '';
      _rootPrefix.text = prefs.getString('s3_root_prefix') ?? '';
      setState(() {
        useSsl = prefs.getBool('s3_use_ssl') ?? true;
        final saved = prefs.getBool('s3_path_style');
        if (saved != null) {
          pathStyle = saved;
          pathStyleTouched = true;
        }
      });
    });
  }

  @override
  void dispose() {
    for (final c in [
      _endpoint,
      _region,
      _bucket,
      _accessKey,
      _secretKey,
      _rootPrefix
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Save is only offered for exactly the values that passed the test, so any
  /// later edit requires testing again.
  void _invalidateTest() {
    if (testSuccess) setState(() => testSuccess = false);
  }

  void _onEndpointChanged() {
    _invalidateTest();
    if (pathStyleTouched) return;
    final next = defaultPathStyleFor(_endpoint.text);
    if (next != pathStyle) setState(() => pathStyle = next);
  }

  SetDriveS3Request _request() => SetDriveS3Request(
        endpoint: _endpoint.text.trim(),
        region: _region.text.trim(),
        bucket: _bucket.text.trim(),
        accessKey: _accessKey.text.trim(),
        secretKey: _secretKey.text,
        root: _rootPrefix.text.trim(),
        useSsl: useSsl,
        pathStyle: pathStyle,
      );

  Future<void> testStorage() async {
    setState(() {
      testSuccess = false;
      testing = true;
      errormsg = null;
    });
    try {
      final rsp = await storage.cli.setDriveS3(_request());
      if (!mounted) return;
      setState(() {
        testSuccess = rsp.success;
        errormsg = rsp.success ? null : rsp.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errormsg = e.toString());
    } finally {
      if (mounted) setState(() => testing = false);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('s3_endpoint', _endpoint.text.trim());
    await prefs.setString('s3_region', _region.text.trim());
    await prefs.setString('s3_bucket', _bucket.text.trim());
    await prefs.setString('s3_access_key', _accessKey.text.trim());
    await prefs.setString('s3_secret_key', _secretKey.text);
    await prefs.setString('s3_root_prefix', _rootPrefix.text.trim());
    await prefs.setBool('s3_use_ssl', useSsl);
    await prefs.setBool('s3_path_style', pathStyle);
    await prefs.setString('drive', driveName[Drive.s3]!);
    settingModel.setRemoteStorageSetted(true);
    assetModel.remoteLastError = null;
    eventBus.fire(RemoteRefreshEvent(refreshUnSync: true));
    if (mounted) Navigator.pop(context);
  }

  Widget _field(String label, TextEditingController c,
      {String? helper, bool obscure = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingLarge,
          vertical: AppSpacing.paddingSmall),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
        ),
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.connectFailed),
        content: Text(msg),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          _field(l10n.s3Endpoint, _endpoint, helper: l10n.s3EndpointHint),
          _field(l10n.s3Region, _region, helper: l10n.s3RegionHint),
          _field(l10n.s3Bucket, _bucket, helper: l10n.s3BucketHint),
          _field(l10n.s3AccessKey, _accessKey),
          _field(l10n.s3SecretKey, _secretKey, obscure: true),
          _field(l10n.s3RootPrefix, _rootPrefix, helper: l10n.s3RootPrefixHint),
          SwitchListTile(
            title: Text(l10n.s3UseSsl),
            value: useSsl,
            onChanged: (v) => setState(() {
              useSsl = v;
              testSuccess = false;
            }),
          ),
          SwitchListTile(
            title: Text(l10n.s3PathStyle),
            subtitle: Text(l10n.s3PathStyleHint),
            value: pathStyle,
            onChanged: (v) => setState(() {
              pathStyle = v;
              pathStyleTouched = true;
              testSuccess = false;
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingLarge,
                    vertical: AppSpacing.paddingSmall),
                child: FilledButton.tonal(
                  onPressed: testing
                      ? null
                      : () => testStorage().then((_) {
                            if (!mounted) return;
                            if (testSuccess) {
                              SnackBarManager.showSnackBar(l10n.testSuccess);
                            } else if (errormsg != null) {
                              _showErrorDialog(errormsg!);
                            }
                          }),
                  child: Text(l10n.testStorage),
                ),
              ),
              Container(
                width: 150,
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingLarge,
                    vertical: AppSpacing.paddingSmall),
                child: FilledButton(
                  onPressed: testSuccess ? _save : null,
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

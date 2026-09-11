import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_config.dart';
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static Future<void> init() async => Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
  static User? get user => client.auth.currentUser;
  static Future<String?> instituteId() async { final r=await client.rpc('get_my_institute_id'); return r?.toString(); }
  static Future<String> role() async { try { final r=await client.rpc('get_my_role'); return '${r ?? 'admin'}'; } catch (_) { return 'admin'; } }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
class Repo {
  static SupabaseClient get db=>SupabaseService.client;
  static Future<String> tenant() async { final id=await SupabaseService.instituteId(); if(id==null||id.isEmpty) throw Exception('Institute not found'); return id; }
  static Future<List<Map<String,dynamic>>> list(String table,{String order='created_at',bool desc=true}) async { final id=await tenant(); final r=await db.from(table).select().eq('institute_id',id).order(order,ascending:!desc); if(r is List) return List<Map<String,dynamic>>.from(r); return []; }
  static Future<void> insert(String table,Map<String,dynamic> values) async { final id=await tenant(); await db.from(table).insert({...values,'institute_id':id}); }
  static Future<void> update(String table,String id,Map<String,dynamic> values) async { await db.from(table).update(values).eq('id',id); }
}

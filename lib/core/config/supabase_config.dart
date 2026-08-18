import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xpkritidsdvirecoujsb.supabase.co/rest/v1/',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhwa3JpdGlkc2R2aXJlY291anNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwMzgwMDUsImV4cCI6MjEwMjYxNDAwNX0.rBki6n88UAJROwyEAqi4Nky8DQ0SAQwW0_8BK93piMk',
  );

  static Future<void> init() async {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    } catch (e) {
      // Graceful fallback if initialization fails or already initialized
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}

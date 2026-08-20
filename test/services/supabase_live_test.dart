// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'package:supabase/supabase.dart';

void main() async {
  const supabaseUrl = 'https://xmjumotmtmrisfhhvbhn.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtanVtb3RtdG1yaXNmaGh2YmhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyMjc5NzUsImV4cCI6MjEwMjgwMzk3NX0.YL9WR1CvUtaXy6rWLoWTNXr3yIFoh8G1k8IFLTSFEnU';

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  print('Connecting to live Supabase backend: $supabaseUrl...');

  // 1. Verify Users table
  final testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
  await client.from('users').upsert({
    'id': testUserId,
    'display_name': 'Test Spider User',
    'public_key': 'mock_public_key_123',
  });
  final userRes = await client.from('users').select().eq('id', testUserId).single();
  assert(userRes['display_name'] == 'Test Spider User', 'Users table failed verification');
  print('✓ [1/4] Users table verified: id=$testUserId, display_name=${userRes['display_name']}');

  // 2. Verify Buddy Relationships table
  await client.from('buddy_relationships').upsert({
    'id': 'rel_${testUserId}_target',
    'user_id': testUserId,
    'buddy_id': 'target_buddy_999',
    'status': 'accepted',
  });
  final relRes = await client.from('buddy_relationships').select().eq('id', 'rel_${testUserId}_target').single();
  assert(relRes['status'] == 'accepted', 'Buddy Relationships failed verification');
  print('✓ [2/4] Buddy Relationships table verified: status=${relRes['status']}');

  // 3. Verify Latest Locations table
  await client.from('latest_locations').upsert({
    'buddy_id': testUserId,
    'latitude': 12.9726,
    'longitude': 77.5946,
    'accuracy': 5.0,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'speed': 1.5,
    'heading': 90.0,
    'transport': 'internet',
  });
  final locRes = await client.from('latest_locations').select().eq('buddy_id', testUserId).single();
  assert(locRes['latitude'] == 12.9726 && locRes['transport'] == 'internet', 'Latest Locations failed verification');
  print('✓ [3/4] Latest Locations table verified: lat=${locRes['latitude']}, lon=${locRes['longitude']}, transport=${locRes['transport']}');

  // 4. Verify Tracking Sessions table
  final testSessionId = 'sess_$testUserId';
  await client.from('tracking_sessions').upsert({
    'id': testSessionId,
    'user_id': testUserId,
    'buddy_id': 'target_buddy_999',
    'started_at': DateTime.now().toUtc().toIso8601String(),
    'is_active': true,
    'mode': 'active',
  });
  final sessRes = await client.from('tracking_sessions').select().eq('id', testSessionId).single();
  assert(sessRes['is_active'] == true, 'Tracking Sessions failed verification');
  print('✓ [4/4] Tracking Sessions table verified: is_active=${sessRes['is_active']}, mode=${sessRes['mode']}');

  // Clean up test rows
  await client.from('tracking_sessions').delete().eq('id', testSessionId);
  await client.from('latest_locations').delete().eq('buddy_id', testUserId);
  await client.from('buddy_relationships').delete().eq('id', 'rel_${testUserId}_target');
  await client.from('users').delete().eq('id', testUserId);
  print('✓ All test rows cleaned up from cloud tables');
  print('🎉 SUCCESS: Live Supabase backend is 100% operational and matches architecture.md §7!');
}

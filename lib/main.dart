import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/app_config.dart';
import 'models/models.dart';
import 'repositories/repository.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const EasyLearnApp());
}

class EasyLearnApp extends StatelessWidget {
  const EasyLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xff155EEF);
    final scheme = ColorScheme.fromSeed(seedColor: blue, brightness: Brightness.light).copyWith(
      primary: blue,
      secondary: const Color(0xff3B82F6),
      surface: Colors.white,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xffF7F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xffF7F9FC),
          foregroundColor: Color(0xff101828),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shadowColor: Color(0x14155EEF),
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xffF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xffE4E7EC))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: blue, width: 1.5)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xffE8F0FF),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (SupabaseService.user == null) return const LoginPage();
        return const HomeShell();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool register = false;
  bool busy = false;
  String message = '';

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => message = 'Email and password are required.');
      return;
    }
    if (register && name.text.trim().isEmpty) {
      setState(() => message = 'Please enter your full name.');
      return;
    }
    setState(() { busy = true; message = ''; });
    try {
      if (register) {
        final result = await SupabaseService.client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': name.text.trim()},
        );
        if (result.session == null && mounted) {
          setState(() => message = 'Account created. Confirm your email, then login.');
        }
      } else {
        await SupabaseService.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } catch (error) {
      if (mounted) setState(() => message = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose(); password.dispose(); name.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xffF3F7FF), Color(0xffFFF8EF)]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width > 700 ? 460 : 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: Container(width: 68, height: 68, decoration: BoxDecoration(color: const Color(0xff155EEF), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x22155EEF), blurRadius: 20, offset: Offset(0, 8))]), child: const Center(child: Text('E', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800))))),
                      const SizedBox(height: 18),
                      Text(AppConfig.appName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xff101828))),
                      const SizedBox(height: 6),
                      Text(register ? 'Create your institute account' : 'Welcome back — sign in to continue', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff667085))),
                      const SizedBox(height: 26),
                      if (register) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 13)],
                      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
                      const SizedBox(height: 13),
                      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
                      if (message.isNotEmpty) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xfffff1f3), borderRadius: BorderRadius.circular(12)), child: Text(message, style: const TextStyle(color: Color(0xffb42318))))],
                      const SizedBox(height: 18),
                      SizedBox(height: 52, child: FilledButton(onPressed: busy ? null : submit, style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(busy ? 'Please wait…' : register ? 'Create account' : 'Login'))),
                      const SizedBox(height: 6),
                      TextButton(onPressed: busy ? null : () => setState(() { register = !register; message = ''; }), child: Text(register ? 'Already have an account? Login' : 'Create a new account')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  String role = 'admin';
  @override void initState() { super.initState(); loadRole(); }
  Future<void> loadRole() async { final value = await SupabaseService.role(); if (mounted) setState(() => role = value); }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[Dashboard(role: role), const StudentsPage(), const FeesPage(), const BatchesPage(), MorePage(role: role)];
    return Scaffold(
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments_rounded), label: 'Fee'),
          NavigationDestination(icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_rounded), label: 'Batches'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded), label: 'More'),
        ],
      ),
    );
  }
}

class Top extends StatelessWidget {
  final String title;
  const Top(this.title, {super.key});
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xff101828)))));
}

class Dashboard extends StatefulWidget {
  final String role;
  const Dashboard({required this.role, super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, String> stats = {
    'Students': '0',
    'Batches': '0',
    'Staff': '0',
    'Collection': '${AppConfig.currency} 0',
  };
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<int> _safeCount(String table, String instituteId) async {
    try {
      final rows = await Repo.db
          .from(table)
          .select('id')
          .eq('institute_id', instituteId);
      return rows.length;
    } catch (error) {
      debugPrint('Dashboard $table: $error');
      return 0;
    }
  }

  Future<double> _safeCollection(String instituteId) async {
    try {
      final start = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      ).toIso8601String();
      final payments = await Repo.db
          .from('fee_payments')
          .select('amount')
          .eq('institute_id', instituteId)
          .gte('paid_at', start);
      return payments.fold<double>(
        0,
        (sum, row) =>
            sum + ((row['amount'] as num?)?.toDouble() ?? 0),
      );
    } catch (error) {
      // Payment RLS/schema problems must never hide the other dashboard counts.
      debugPrint('Dashboard fee_payments: $error');
      return 0;
    }
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final instituteId = await Repo.tenant();

      // Load every metric independently. One failing table must not reset all cards to 0.
      final studentsFuture = _safeCount('students', instituteId);
      final batchesFuture = _safeCount('batches', instituteId);
      final teachersFuture = _safeCount('teachers', instituteId);
      final collectionFuture = _safeCollection(instituteId);

      final students = await studentsFuture;
      final batches = await batchesFuture;
      final teachers = await teachersFuture;
      final total = await collectionFuture;

      if (mounted) {
        setState(() {
          stats = {
            'Students': '$students',
            'Batches': '$batches',
            'Staff': '$teachers',
            'Collection':
                '${AppConfig.currency} ${NumberFormat('#,##0').format(total)}',
          };
        });
      }
    } catch (error) {
      debugPrint('Dashboard tenant: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Students', stats['Students'] ?? '0', Icons.people_alt_rounded),
      ('Batches', stats['Batches'] ?? '0', Icons.class_rounded),
      ('Staff', stats['Staff'] ?? '0', Icons.badge_rounded),
      ('Collection', stats['Collection'] ?? '${AppConfig.currency} 0', Icons.account_balance_wallet_rounded),
    ];

    return RefreshIndicator(
      color: const Color(0xff155EEF),
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const Top('Easylearn Institute'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff0F5FEF), Color(0xff3B82F6)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26155EEF),
                    blurRadius: 26,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Institute Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Role: ${widget.role}',
                          style: const TextStyle(
                            color: Color(0xffE7EEFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                          style: const TextStyle(
                            color: Color(0xffD7E5FF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh dashboard',
                    onPressed: loading ? null : load,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff101828),
                      ),
                ),
                Text(
                  'Live data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xff667085),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(44),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 4
                      : (constraints.maxWidth >= 620 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 1 ? 2.25 : 1.78,
                    ),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (i == 0) _open(const StudentsPage());
                            if (i == 1) _open(const BatchesPage());
                            if (i == 2) _open(MorePage(role: widget.role));
                            if (i == 3) _open(const FeesPage());
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xffE6ECF5)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0F155EEF),
                                  blurRadius: 14,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffEEF4FF),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(item.$3, color: const Color(0xff155EEF)),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 19,
                                      color: Color(0xff98A2B3),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.$1,
                                      style: const TextStyle(
                                        color: Color(0xff667085),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xff101828),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff101828),
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final actions = [
                  _QuickActionData(Icons.person_add_alt_1_rounded, 'Add Student', () { _open(const StudentFormPage()); }),
                  _QuickActionData(Icons.add_box_rounded, 'Add Batch', () { _open(const BatchFormPage()); }),
                  _QuickActionData(Icons.receipt_long_rounded, 'Create Fee', () { _open(const FeeFormPage()); }),
                ];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: compact ? 1 : 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: compact ? 5.4 : 2.8,
                  ),
                  itemBuilder: (_, i) => _QuickAction(
                    icon: actions[i].icon,
                    label: actions[i].label,
                    onTap: actions[i].onTap,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionData(this.icon, this.label, this.onTap);
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffE4EAF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C155EEF),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xffEEF4FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xff155EEF), size: 19),
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff344054),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Student> students = [];
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = await Repo.list('students');
      students = rows.map(Student.fromMap).toList();
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = students.where((student) { final text='${student.name} ${student.studentId} ${student.phone}'.toLowerCase(); return text.contains(query.toLowerCase()); }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Students', style: TextStyle(fontWeight: FontWeight.w800)), actions: [Padding(padding: const EdgeInsets.only(right: 14), child: IconButton(style: IconButton.styleFrom(backgroundColor: const Color(0xff155EEF)), color: Colors.white, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFormPage())).then((_) => load()), icon: const Icon(Icons.add_rounded)))],),
      body: Column(children: [Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 12), child: TextField(onChanged: (value)=>setState(()=>query=value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search name, ID or phone'))), Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : filtered.isEmpty ? const Center(child: Text('No students found.')) : ListView.separated(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), itemCount: filtered.length, separatorBuilder: (_,__)=>const SizedBox(height:10), itemBuilder: (_,index){ final student=filtered[index]; return Card(child: InkWell(borderRadius: BorderRadius.circular(18), onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFormPage(student: student))).then((_)=>load()), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 48,height:48,decoration: BoxDecoration(color: const Color(0xffEEF4FF),borderRadius: BorderRadius.circular(14)),child: Center(child: Text(student.name.isEmpty?'?':student.name[0].toUpperCase(),style: const TextStyle(color: Color(0xff155EEF),fontSize:18,fontWeight: FontWeight.w800)))), const SizedBox(width:12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(student.name,style: const TextStyle(fontWeight: FontWeight.w800,fontSize:15)), const SizedBox(height:4), Text('${student.studentId} • ${student.phone}',style: const TextStyle(color: Color(0xff667085),fontSize:12)), Text('Guardian: ${student.guardian}',style: const TextStyle(color: Color(0xff98A2B3),fontSize:11))])), const Icon(Icons.chevron_right_rounded,color: Color(0xff98A2B3))])))); }) )])
    );
  }
}

class StudentFormPage extends StatefulWidget {
  final Student? student;
  const StudentFormPage({this.student, super.key});

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final name = TextEditingController();
  final studentId = TextEditingController();
  final phone = TextEditingController();
  final guardian = TextEditingController();
  final guardianPhone = TextEditingController();
  final address = TextEditingController();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    if (s != null) {
      name.text = s.name;
      studentId.text = s.studentId;
      phone.text = s.phone;
      guardian.text = s.guardian;
      guardianPhone.text = s.guardianPhone;
    }
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final values = {
        'student_id': studentId.text.trim().isEmpty ? null : studentId.text.trim(),
        'full_name': name.text.trim(),
        'phone': phone.text.trim(),
        'guardian_name': guardian.text.trim(),
        'guardian_phone': guardianPhone.text.trim(),
        'address': address.text.trim(),
        'status': 'active',
      };
      if (widget.student == null) {
        await Repo.insert('students', {'user_id': SupabaseService.user!.id, ...values});
      } else {
        await Repo.update('students', widget.student!.id, values);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    studentId.dispose();
    phone.dispose();
    guardian.dispose();
    guardianPhone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.student == null ? 'Add Student' : 'Edit Student')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name *')),
          const SizedBox(height: 12),
          TextField(controller: studentId, decoration: const InputDecoration(labelText: 'Student ID')),
          const SizedBox(height: 12),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: guardian, decoration: const InputDecoration(labelText: 'Guardian name')),
          const SizedBox(height: 12),
          TextField(controller: guardianPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Guardian phone')),
          const SizedBox(height: 12),
          TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 20),
          FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Saving…' : 'Save Student')),
        ],
      ),
    );
  }
}

class BatchesPage extends StatefulWidget {
  const BatchesPage({super.key});

  @override
  State<BatchesPage> createState() => _BatchesPageState();
}

class _BatchesPageState extends State<BatchesPage> {
  List<Batch> batches = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = await Repo.list('batches');
      batches = rows.map(Batch.fromMap).toList();
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batches'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchFormPage())).then((_) => load()),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : batches.isEmpty
              ? const Center(child: Text('No batches found. Add the first batch.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: batches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final batch = batches[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.class_)),
                        title: Text(batch.name),
                        subtitle: Text('Fee: ${AppConfig.currency}${batch.fee.toStringAsFixed(0)} • ${batch.status}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BatchStudentsPage(batch: batch)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class BatchFormPage extends StatefulWidget {
  const BatchFormPage({super.key});

  @override
  State<BatchFormPage> createState() => _BatchFormPageState();
}

class _BatchFormPageState extends State<BatchFormPage> {
  final name = TextEditingController();
  final room = TextEditingController();
  final fee = TextEditingController();
  String? course;
  String? teacher;
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> teachers = [];
  bool busy = false;

  @override
  void initState() {
    super.initState();
    loadOptions();
  }

  Future<void> loadOptions() async {
    try {
      courses = await Repo.list('courses');
      teachers = await Repo.list('teachers');
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    }
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || course == null) return;
    setState(() => busy = true);
    try {
      await Repo.insert('batches', {
        'name': name.text.trim(),
        'course_id': course,
        'teacher_id': teacher,
        'room': room.text.trim().isEmpty ? null : room.text.trim(),
        'start_date': DateTime.now().toIso8601String().substring(0, 10),
        'fee': double.tryParse(fee.text) ?? 0,
        'status': 'active',
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    room.dispose();
    fee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Batch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Batch name *')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: course,
            decoration: const InputDecoration(labelText: 'Course *'),
            items: courses.map((row) => DropdownMenuItem(value: '${row['id']}', child: Text('${row['name'] ?? 'Course'}'))).toList(),
            onChanged: (value) => setState(() => course = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: teacher,
            decoration: const InputDecoration(labelText: 'Teacher'),
            items: teachers.map((row) => DropdownMenuItem(value: '${row['id']}', child: Text('${row['name'] ?? row['full_name'] ?? 'Teacher'}'))).toList(),
            onChanged: (value) => setState(() => teacher = value),
          ),
          const SizedBox(height: 12),
          TextField(controller: room, decoration: const InputDecoration(labelText: 'Room')),
          const SizedBox(height: 12),
          TextField(controller: fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Batch fee (৳)')),
          const SizedBox(height: 20),
          FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Saving…' : 'Save Batch')),
        ],
      ),
    );
  }
}

class BatchStudentsPage extends StatefulWidget {
  final Batch batch;
  const BatchStudentsPage({required this.batch, super.key});

  @override
  State<BatchStudentsPage> createState() => _BatchStudentsPageState();
}

class _BatchStudentsPageState extends State<BatchStudentsPage> {
  List<Map<String, dynamic>> students = [];
  Set<String> selected = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final instituteId = await Repo.tenant();
      students = await Repo.db.from('students').select('id,student_id,full_name,phone').eq('institute_id', instituteId).eq('status', 'active');
      final assigned = await Repo.db.from('batch_students').select('student_id').eq('institute_id', instituteId).eq('batch_id', widget.batch.id);
      selected = assigned.map<String>((row) => '${row['student_id']}').toSet();
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    try {
      final instituteId = await Repo.tenant();
      await Repo.db.from('batch_students').delete().eq('institute_id', instituteId).eq('batch_id', widget.batch.id);
      if (selected.isNotEmpty) {
        await Repo.db.from('batch_students').insert(
          selected.map((studentId) => {'institute_id': instituteId, 'batch_id': widget.batch.id, 'student_id': studentId}).toList(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students • ${widget.batch.name}'),
        actions: [IconButton(onPressed: save, icon: const Icon(Icons.save))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: students.map((row) {
                final id = '${row['id']}';
                return CheckboxListTile(
                  value: selected.contains(id),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      selected.add(id);
                    } else {
                      selected.remove(id);
                    }
                  }),
                  title: Text('${row['full_name'] ?? ''}'),
                  subtitle: Text('${row['student_id'] ?? ''} • ${row['phone'] ?? ''}'),
                );
              }).toList(),
            ),
    );
  }
}

class FeesPage extends StatefulWidget {
  const FeesPage({super.key});

  @override
  State<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final instituteId = await Repo.tenant();
      rows = await Repo.db.from('fees').select('id,student_id,fee_type,amount,due_date,status,created_at').eq('institute_id', instituteId).order('created_at', ascending: false);
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees & Payments'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeFormPage())).then((_) => load()),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? const Center(child: Text('No fees found. Create the first fee.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final row = rows[index];
                    return Card(
                      child: ListTile(
                        title: Text('${row['fee_type'] ?? 'Fee'} • ${AppConfig.currency}${row['amount'] ?? 0}'),
                        subtitle: Text('Amount: ${AppConfig.currency}${row['amount'] ?? 0} • ${row['status'] ?? ''}\nStudent: ${row['student_id'] ?? ''}'),
                        isThreeLine: true,
                        trailing: FilledButton.tonal(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollectPaymentPage(fee: row))).then((_) => load()),
                          child: const Text('Pay'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class FeeFormPage extends StatefulWidget {
  const FeeFormPage({super.key});

  @override
  State<FeeFormPage> createState() => _FeeFormPageState();
}

class _FeeFormPageState extends State<FeeFormPage> {
  List<Map<String, dynamic>> students = [];
  String? student;
  final amount = TextEditingController();
  final discount = TextEditingController();
  final type = TextEditingController(text: 'Monthly');
  bool busy = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final instituteId = await Repo.tenant();
      students = await Repo.db.from('students').select('id,student_id,full_name').eq('institute_id', instituteId).eq('status', 'active').order('full_name');
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    }
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text) ?? 0;
    final discountValue = double.tryParse(discount.text) ?? 0;
    if (student == null) {
      showMessage(context, 'Please select a student.');
      return;
    }
    if (value <= 0) {
      showMessage(context, 'Please enter a valid fee amount.');
      return;
    }
    if (discountValue < 0 || discountValue > value) {
      showMessage(context, 'Discount cannot be greater than the fee amount.');
      return;
    }

    setState(() => busy = true);
    try {
      await Repo.insert('fees', {
        'student_id': student,
        'title': type.text.trim().isEmpty ? 'Monthly Fee' : type.text.trim(),
        'fee_type': type.text.trim().isEmpty ? 'Other' : type.text.trim(),
        'amount': value,
        'discount': discountValue,
        'paid_amount': 0,
        'due_amount': value - discountValue,
        'due_date': DateTime.now().toIso8601String().substring(0, 10),
        'status': 'unpaid',
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    discount.dispose();
    type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Fee')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: student,
            decoration: const InputDecoration(labelText: 'Student *'),
            items: students.map((row) => DropdownMenuItem(value: '${row['id']}', child: Text('${row['full_name']} • ${row['student_id']}'))).toList(),
            onChanged: (value) => setState(() => student = value),
          ),
          const SizedBox(height: 12),
          TextField(controller: type, decoration: const InputDecoration(labelText: 'Fee type')),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (৳) *')),
          const SizedBox(height: 12),
          TextField(controller: discount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount (৳)')),
          const SizedBox(height: 20),
          FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Saving…' : 'Create Fee')),
        ],
      ),
    );
  }
}

class CollectPaymentPage extends StatefulWidget {
  final Map<String, dynamic> fee;
  const CollectPaymentPage({required this.fee, super.key});

  @override
  State<CollectPaymentPage> createState() => _CollectPaymentPageState();
}

class _CollectPaymentPageState extends State<CollectPaymentPage> {
  final amount = TextEditingController();
  String method = 'Cash';
  bool busy = false;

  Future<void> pay() async {
    final value = double.tryParse(amount.text) ?? 0;
    if (value <= 0) return;

    setState(() => busy = true);
    try {
      await SupabaseService.client.rpc(
        'create_payment_and_receipt',
        params: {
          'p_fee_id': widget.fee['id'],
          'p_amount': value,
          'p_method': method,
          'p_transaction_reference': null,
        },
      );
      if (mounted) {
        showMessage(context, 'Payment saved and receipt created.');
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collect Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Fee: ${AppConfig.currency}${widget.fee['amount'] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Payment amount (৳)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: method,
            items: const [
              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              DropdownMenuItem(value: 'bKash', child: Text('bKash')),
              DropdownMenuItem(value: 'Nagad', child: Text('Nagad')),
              DropdownMenuItem(value: 'Rocket', child: Text('Rocket')),
              DropdownMenuItem(value: 'Bank', child: Text('Bank')),
            ],
            onChanged: (value) => setState(() => method = value ?? 'Cash'),
            decoration: const InputDecoration(labelText: 'Method'),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: busy ? null : pay, child: Text(busy ? 'Saving…' : 'Confirm Payment')),
        ],
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  final String role;
  const MorePage({required this.role, super.key});

  static const items = <String, IconData>{
    'Staff': Icons.badge_rounded,
    'Courses': Icons.menu_book_rounded,
    'Attendance': Icons.fact_check_rounded,
    'Routine': Icons.schedule_rounded,
    'Homework': Icons.assignment_rounded,
    'Assignments': Icons.description_rounded,
    'Exams & Results': Icons.school_rounded,
    'Enquiries': Icons.contact_phone_rounded,
    'Salary': Icons.payments_rounded,
    'Expenses': Icons.receipt_long_rounded,
    'Profit & Loss': Icons.analytics_rounded,
    'Reports': Icons.bar_chart_rounded,
    'Notifications': Icons.notifications_rounded,
    'Archives': Icons.archive_rounded,
    'Settings': Icons.settings_rounded,
    'Subscription': Icons.card_membership_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Management', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff155EEF), Color(0xff3B82F6)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Color(0x22155EEF), blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Easylearn Control Center', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Signed in as ${role.toUpperCase()}', style: const TextStyle(color: Color(0xffE5EDFF), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Modules', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xff101828))),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 3 : 2;
              final gap = 10.0;
              final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: items.entries.map((entry) {
                  return SizedBox(
                    width: width,
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GenericModulePage(
                              title: entry.key,
                              table: tableFor(entry.key),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xffEEF4FF),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(entry.value, color: const Color(0xff155EEF)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff344054))),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xff98A2B3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => SupabaseService.client.auth.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  static String tableFor(String title) {
    switch (title) {
      case 'Staff': return 'teachers';
      case 'Courses': return 'courses';
      case 'Attendance': return 'attendance';
      case 'Routine': return 'routines';
      case 'Homework': return 'homework';
      case 'Assignments': return 'assignments';
      case 'Exams & Results': return 'exams';
      case 'Enquiries': return 'enquiries';
      case 'Salary': return 'salaries';
      case 'Expenses': return 'expenses';
      case 'Notifications': return 'notifications';
      case 'Archives': return 'students';
      case 'Subscription': return 'subscriptions';
      default: return 'students';
    }
  }
}

class GenericModulePage extends StatefulWidget {
  final String title;
  final String table;
  const GenericModulePage({required this.title, required this.table, super.key});

  @override
  State<GenericModulePage> createState() => _GenericModulePageState();
}

class _GenericModulePageState extends State<GenericModulePage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await Repo.list(widget.table);
    } catch (error) {
      if (mounted) showMessage(context, 'Could not load ${widget.title}: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> addRecord() async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _GenericAddDialog(title: widget.title, table: widget.table),
    );
    if (data == null) return;
    try {
      await Repo.insert(widget.table, data);
      if (mounted) {
        showMessage(context, '${widget.title} saved successfully');
        await load();
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Save failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = rows.where((row) {
      if (query.trim().isEmpty) return true;
      final text = row.values.map((e) => '$e').join(' ').toLowerCase();
      return text.contains(query.trim().toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded))],
      ),
      floatingActionButton: _supportsAdd(widget.table)
          ? FloatingActionButton.extended(
              onPressed: addRecord,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                children: [
                  TextField(
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search records…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_rounded, size: 44, color: Color(0xff98A2B3)),
                          const SizedBox(height: 10),
                          Text('No ${widget.title.toLowerCase()} records yet.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff475467))),
                          if (_supportsAdd(widget.table)) ...[
                            const SizedBox(height: 5),
                            const Text('Use Add to create the first record.', style: TextStyle(color: Color(0xff667085), fontSize: 12)),
                          ],
                        ],
                      ),
                    )
                  else
                    ...filtered.map((row) {
                      final label = row['name'] ?? row['full_name'] ?? row['title'] ?? row['category'] ?? row['fee_type'] ?? row['description'] ?? row['status'] ?? row['id'];
                      final status = row['status'];
                      final amount = row['amount'] ?? row['payable'] ?? row['paid'] ?? row['fee'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: const Color(0xffEEF4FF), borderRadius: BorderRadius.circular(13)),
                              child: const Icon(Icons.description_rounded, color: Color(0xff155EEF)),
                            ),
                            title: Text('$label', style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: status == null ? null : Text('Status: $status'),
                            trailing: amount == null ? null : Text('৳${amount}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff155EEF))),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  bool _supportsAdd(String table) => const {
        'teachers', 'courses', 'homework', 'assignments', 'enquiries', 'expenses', 'notifications',
      }.contains(table);
}

class _GenericAddDialog extends StatefulWidget {
  final String title;
  final String table;
  const _GenericAddDialog({required this.title, required this.table});

  @override
  State<_GenericAddDialog> createState() => _GenericAddDialogState();
}

class _GenericAddDialogState extends State<_GenericAddDialog> {
  final first = TextEditingController();
  final second = TextEditingController();
  final third = TextEditingController();
  final fourth = TextEditingController();

  String firstLabel = 'Name';
  String secondLabel = 'Description';
  String thirdLabel = 'Phone';
  String fourthLabel = 'Amount';

  @override
  void initState() {
    super.initState();
    switch (widget.table) {
      case 'courses':
        firstLabel = 'Course name'; secondLabel = 'Description'; thirdLabel = 'Duration'; fourthLabel = 'Fee';
        break;
      case 'homework':
      case 'assignments':
        firstLabel = 'Title'; secondLabel = 'Description'; thirdLabel = 'Deadline (YYYY-MM-DD)'; fourthLabel = 'Attachment URL';
        break;
      case 'enquiries':
        firstLabel = 'Name'; secondLabel = 'Phone'; thirdLabel = 'Course / Interest'; fourthLabel = 'Note';
        break;
      case 'expenses':
        firstLabel = 'Category'; secondLabel = 'Description'; thirdLabel = 'Method'; fourthLabel = 'Amount';
        break;
      case 'notifications':
        firstLabel = 'Title'; secondLabel = 'Message'; thirdLabel = 'Type'; fourthLabel = 'Target';
        break;
      case 'teachers':
        firstLabel = 'Staff name'; secondLabel = 'Designation'; thirdLabel = 'Phone'; fourthLabel = 'Salary';
        break;
    }
  }

  @override
  void dispose() {
    first.dispose(); second.dispose(); third.dispose(); fourth.dispose(); super.dispose();
  }

  Map<String, dynamic>? buildData() {
    if (first.text.trim().isEmpty) return null;
    switch (widget.table) {
      case 'teachers':
        return {'name': first.text.trim(), 'full_name': first.text.trim(), 'designation': second.text.trim().isEmpty ? 'Teacher' : second.text.trim(), 'phone': third.text.trim(), 'salary': double.tryParse(fourth.text.trim()) ?? 0, 'status': 'active'};
      case 'courses':
        return {'name': first.text.trim(), 'description': second.text.trim(), 'duration': third.text.trim(), 'fee': double.tryParse(fourth.text.trim()) ?? 0, 'status': 'active'};
      case 'homework':
      case 'assignments':
        return {'title': first.text.trim(), 'description': second.text.trim(), 'deadline': third.text.trim().isEmpty ? null : third.text.trim(), 'attachment_url': fourth.text.trim().isEmpty ? null : fourth.text.trim()};
      case 'enquiries':
        return {'name': first.text.trim(), 'phone': second.text.trim(), 'source': third.text.trim(), 'notes': fourth.text.trim(), 'status': 'new'};
      case 'expenses':
        return {'category': first.text.trim(), 'description': second.text.trim(), 'method': third.text.trim().isEmpty ? 'Cash' : third.text.trim(), 'amount': double.tryParse(fourth.text.trim()) ?? 0};
      case 'notifications':
        return {'title': first.text.trim(), 'body': second.text.trim(), 'message': second.text.trim(), 'type': third.text.trim().isEmpty ? 'info' : third.text.trim()};
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: first, decoration: InputDecoration(labelText: firstLabel)),
            const SizedBox(height: 10),
            TextField(controller: second, decoration: InputDecoration(labelText: secondLabel)),
            const SizedBox(height: 10),
            TextField(controller: third, decoration: InputDecoration(labelText: thirdLabel)),
            const SizedBox(height: 10),
            TextField(controller: fourth, keyboardType: fourthLabel == 'Amount' || fourthLabel == 'Fee' || fourthLabel == 'Salary' ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: fourthLabel)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, buildData()), child: const Text('Save')),
      ],
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

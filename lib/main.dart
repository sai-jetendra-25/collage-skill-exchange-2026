import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// MODELS
// ============================================================

class Entry {
  final String title, sub, desc;
  Entry(this.title, this.sub, [this.desc = '']);
  Map<String, dynamic> toJson() => {'t': title, 's': sub, 'd': desc};
  factory Entry.fromJson(Map<String, dynamic> j) =>
      Entry(j['t'], j['s'], j['d'] ?? '');
}

class Student {
  final String id;
  String name, branch, year, headline, about, location;
  List<String> teach, learn;
  List<Entry> experience, projects;
  Map<String, List<String>> endorsements; // skill -> endorser ids
  bool demo;
  int done, ratingSum, ratingN;

  Student({
    required this.id,
    required this.name,
    this.branch = '',
    this.year = '',
    this.headline = '',
    this.about = '',
    this.location = '',
    List<String>? teach,
    List<String>? learn,
    List<Entry>? experience,
    List<Entry>? projects,
    Map<String, List<String>>? endorsements,
    this.demo = false,
    this.done = 0,
    this.ratingSum = 0,
    this.ratingN = 0,
  })  : teach = teach ?? [],
        learn = learn ?? [],
        experience = experience ?? [],
        projects = projects ?? [],
        endorsements = endorsements ?? {};

  double? get rating => ratingN == 0 ? null : ratingSum / ratingN;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'branch': branch,
        'year': year,
        'headline': headline,
        'about': about,
        'location': location,
        'teach': teach,
        'learn': learn,
        'exp': experience.map((e) => e.toJson()).toList(),
        'proj': projects.map((e) => e.toJson()).toList(),
        'endo': endorsements,
        'demo': demo,
        'done': done,
        'rs': ratingSum,
        'rn': ratingN,
      };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        name: j['name'],
        branch: j['branch'] ?? '',
        year: j['year'] ?? '',
        headline: j['headline'] ?? '',
        about: j['about'] ?? '',
        location: j['location'] ?? '',
        teach: List<String>.from(j['teach'] ?? []),
        learn: List<String>.from(j['learn'] ?? []),
        experience: (j['exp'] as List? ?? [])
            .map((e) => Entry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        projects: (j['proj'] as List? ?? [])
            .map((e) => Entry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        endorsements: (j['endo'] as Map? ?? {})
            .map((k, v) => MapEntry(k as String, List<String>.from(v))),
        demo: j['demo'] ?? false,
        done: j['done'] ?? 0,
        ratingSum: j['rs'] ?? 0,
        ratingN: j['rn'] ?? 0,
      );
}

class Msg {
  final String from, text;
  final int time;
  Msg(this.from, this.text, this.time);
  Map<String, dynamic> toJson() => {'f': from, 't': text, 'ts': time};
  factory Msg.fromJson(Map<String, dynamic> j) => Msg(j['f'], j['t'], j['ts']);
}

class Swap {
  final String id, from, to, wanted, offered, message;
  String status; // pending | accepted | declined
  bool completed;
  final int createdAt;
  final List<Msg> msgs;
  final Map<String, int> ratings; // raterId -> stars

  Swap({
    required this.id,
    required this.from,
    required this.to,
    required this.wanted,
    required this.offered,
    this.message = '',
    this.status = 'pending',
    this.completed = false,
    required this.createdAt,
    List<Msg>? msgs,
    Map<String, int>? ratings,
  })  : msgs = msgs ?? [],
        ratings = ratings ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
        'wanted': wanted,
        'offered': offered,
        'message': message,
        'status': status,
        'completed': completed,
        'createdAt': createdAt,
        'msgs': msgs.map((m) => m.toJson()).toList(),
        'ratings': ratings,
      };

  factory Swap.fromJson(Map<String, dynamic> j) => Swap(
        id: j['id'],
        from: j['from'],
        to: j['to'],
        wanted: j['wanted'],
        offered: j['offered'],
        message: j['message'] ?? '',
        status: j['status'],
        completed: j['completed'] ?? false,
        createdAt: j['createdAt'],
        msgs: (j['msgs'] as List)
            .map((m) => Msg.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        ratings: Map<String, int>.from(j['ratings'] ?? {}),
      );
}

// ============================================================
// SEED DATA
// ============================================================

Map<String, List<String>> _endo(Map<String, int> m) => m.map(
      (k, n) => MapEntry(k, List.generate(n, (i) => 'seed_$i')),
    );

List<Student> _seedStudents() => [
      Student(
        id: 'demo1@college.ac.in',
        name: 'Ravi Kumar',
        branch: 'CSE',
        year: '3rd Year',
        headline: 'Python developer • Guitarist • Hackathon finalist',
        location: 'Hyderabad, Telangana',
        about:
            'Third-year CSE student who loves automation and backend work. I play guitar on weekends and run a small jam club on campus.',
        teach: ['Python', 'Guitar', 'Git'],
        learn: ['Flutter', 'Public Speaking'],
        experience: [
          Entry('Python Intern', 'TechNova Labs • 2 months',
              'Built scripts to clean and visualise sales data.'),
          Entry('Club Lead', 'College Music Club',
              'Organised 4 open-mic events.'),
        ],
        projects: [
          Entry('Attendance Tracker', 'Python • Flask',
              'Web app used by 3 classes to track attendance.'),
        ],
        endorsements: _endo({'Python': 14, 'Guitar': 9, 'Git': 5}),
        demo: true,
        done: 6,
        ratingSum: 28,
        ratingN: 6,
      ),
      Student(
        id: 'demo2@college.ac.in',
        name: 'Ananya Rao',
        branch: 'ECE',
        year: '4th Year',
        headline: 'Flutter & UI/UX designer • Google DSC member',
        location: 'Hyderabad, Telangana',
        about:
            'I design and ship mobile apps. Happy to teach Flutter basics and Figma. Want to finally learn guitar!',
        teach: ['Flutter', 'UI Design', 'Figma'],
        learn: ['Guitar', 'Python'],
        experience: [
          Entry('Mobile App Intern', 'PixelCraft Studio • 3 months',
              'Shipped two Flutter apps to the Play Store.'),
          Entry('Design Lead', 'DSC College Chapter'),
        ],
        projects: [
          Entry('Campus Bus Tracker', 'Flutter • Firebase',
              'Live bus locations for 500+ students.'),
          Entry('Portfolio Redesign', 'Figma'),
        ],
        endorsements: _endo({'Flutter': 18, 'UI Design': 12, 'Figma': 7}),
        demo: true,
        done: 9,
        ratingSum: 44,
        ratingN: 9,
      ),
      Student(
        id: 'demo3@college.ac.in',
        name: 'Karthik Reddy',
        branch: 'IT',
        year: '3rd Year',
        headline: 'DSA mentor • 450+ LeetCode problems',
        location: 'Warangal, Telangana',
        about:
            'Competitive programmer who enjoys explaining problem-solving patterns. Looking to pick up Python for data work.',
        teach: ['DSA', 'Java', 'C++'],
        learn: ['Python', 'Flutter'],
        experience: [
          Entry('Teaching Assistant', 'Dept. of IT',
              'Helped juniors with data structures lab.'),
        ],
        projects: [
          Entry('Algo Visualizer', 'Java • Swing',
              'Visualises sorting and graph algorithms.'),
        ],
        endorsements: _endo({'DSA': 20, 'Java': 11, 'C++': 6}),
        demo: true,
        done: 11,
        ratingSum: 53,
        ratingN: 11,
      ),
      Student(
        id: 'demo4@college.ac.in',
        name: 'Priya Sharma',
        branch: 'CSE (AIML)',
        year: '2nd Year',
        headline: 'Designer & public speaker • Debate club captain',
        location: 'Hyderabad, Telangana',
        about:
            'Creative student who loves visual storytelling and speaking on stage. Currently trying to crack DSA.',
        teach: ['Photoshop', 'Public Speaking', 'Canva'],
        learn: ['DSA', 'Python'],
        experience: [
          Entry('Captain', 'College Debate Club', 'Won inter-college debate 2025.'),
        ],
        projects: [
          Entry('Fest Branding Kit', 'Photoshop • Illustrator',
              'Posters and social media assets for the annual fest.'),
        ],
        endorsements: _endo({'Photoshop': 10, 'Public Speaking': 15, 'Canva': 4}),
        demo: true,
        done: 5,
        ratingSum: 24,
        ratingN: 5,
      ),
      Student(
        id: 'demo5@college.ac.in',
        name: 'Arjun Mehta',
        branch: 'Mechanical',
        year: '4th Year',
        headline: 'CAD engineer • Excel power user',
        location: 'Secunderabad, Telangana',
        about:
            'Mechanical student who lives in AutoCAD and Excel. Want to learn Python to automate analysis.',
        teach: ['AutoCAD', 'Excel', 'SolidWorks'],
        learn: ['Python', 'Photoshop'],
        experience: [
          Entry('Design Intern', 'Precision Tools Pvt Ltd • 2 months',
              'Drafted 40+ component drawings.'),
        ],
        projects: [
          Entry('Go-Kart Chassis', 'SolidWorks',
              'Led chassis design for the SAE team.'),
        ],
        endorsements: _endo({'AutoCAD': 13, 'Excel': 17, 'SolidWorks': 8}),
        demo: true,
        done: 7,
        ratingSum: 33,
        ratingN: 7,
      ),
      Student(
        id: 'demo6@college.ac.in',
        name: 'Sneha Patel',
        branch: 'CSE',
        year: '3rd Year',
        headline: 'Machine learning enthusiast • Kaggle contributor',
        location: 'Hyderabad, Telangana',
        about:
            'I train small ML models and write about them. Can teach pandas, scikit-learn and basic ML. Want to build a mobile front-end.',
        teach: ['Machine Learning', 'Pandas', 'SQL'],
        learn: ['Flutter', 'UI Design'],
        experience: [
          Entry('Data Science Intern', 'InsightAI • 3 months',
              'Built a churn prediction model.'),
        ],
        projects: [
          Entry('Crop Disease Detector', 'Python • TensorFlow',
              '92% accuracy on a public dataset.'),
        ],
        endorsements: _endo({'Machine Learning': 16, 'Pandas': 9, 'SQL': 8}),
        demo: true,
        done: 8,
        ratingSum: 39,
        ratingN: 8,
      ),
      Student(
        id: 'demo7@college.ac.in',
        name: 'Rohit Verma',
        branch: 'EEE',
        year: '2nd Year',
        headline: 'Arduino tinkerer • Robotics club member',
        location: 'Hyderabad, Telangana',
        about:
            'I build small robots and IoT gadgets. Looking for someone to teach me web development.',
        teach: ['Arduino', 'Embedded C', 'Soldering'],
        learn: ['Web Development', 'Python'],
        experience: [
          Entry('Member', 'Robotics Club', 'Built a line-following robot.'),
        ],
        projects: [
          Entry('Smart Plant Waterer', 'Arduino • IoT',
              'Auto-waters plants based on soil moisture.'),
        ],
        endorsements: _endo({'Arduino': 9, 'Embedded C': 5, 'Soldering': 4}),
        demo: true,
        done: 3,
        ratingSum: 14,
        ratingN: 3,
      ),
      Student(
        id: 'demo8@college.ac.in',
        name: 'Meera Nair',
        branch: 'IT',
        year: '4th Year',
        headline: 'Full-stack developer • Open source contributor',
        location: 'Bengaluru, Karnataka',
        about:
            'Placed at a product company. Happy to mentor on React, Node and interview prep. I want to get better at public speaking.',
        teach: ['Web Development', 'React', 'Node.js', 'Interview Prep'],
        learn: ['Public Speaking', 'Photoshop'],
        experience: [
          Entry('SDE Intern', 'CloudNest • 6 months',
              'Worked on a React dashboard used by 2k users.'),
        ],
        projects: [
          Entry('CollegeConnect', 'React • Node • MongoDB',
              'Event portal used by 3 departments.'),
        ],
        endorsements: _endo(
            {'Web Development': 19, 'React': 14, 'Node.js': 10, 'Interview Prep': 12}),
        demo: true,
        done: 13,
        ratingSum: 64,
        ratingN: 13,
      ),
      Student(
        id: 'demo9@college.ac.in',
        name: 'Imran Shaik',
        branch: 'Civil',
        year: '3rd Year',
        headline: 'Structural design • STAAD Pro & Revit',
        location: 'Hyderabad, Telangana',
        about:
            'Passionate about sustainable buildings. Can teach STAAD Pro and Revit basics. Interested in Excel automation.',
        teach: ['STAAD Pro', 'Revit', 'AutoCAD'],
        learn: ['Excel', 'Python'],
        experience: [
          Entry('Site Trainee', 'BuildRight Constructions • 1 month'),
        ],
        projects: [
          Entry('Low-cost Housing Model', 'Revit',
              'Won department project expo.'),
        ],
        endorsements: _endo({'STAAD Pro': 7, 'Revit': 6, 'AutoCAD': 8}),
        demo: true,
        done: 2,
        ratingSum: 9,
        ratingN: 2,
      ),
      Student(
        id: 'demo10@college.ac.in',
        name: 'Divya Menon',
        branch: 'ECE',
        year: '2nd Year',
        headline: 'Video editor & photographer',
        location: 'Hyderabad, Telangana',
        about:
            'I shoot and edit videos for campus events. Can teach Premiere Pro and basic photography. Learning guitar on the side.',
        teach: ['Video Editing', 'Photography', 'Premiere Pro'],
        learn: ['Guitar', 'Public Speaking'],
        experience: [
          Entry('Media Head', 'College Fest Committee'),
        ],
        projects: [
          Entry('Campus Documentary', 'Premiere Pro',
              '12-minute film shown at the annual day.'),
        ],
        endorsements: _endo({'Video Editing': 11, 'Photography': 9, 'Premiere Pro': 6}),
        demo: true,
        done: 4,
        ratingSum: 19,
        ratingN: 4,
      ),
      Student(
        id: 'demo11@college.ac.in',
        name: 'Vikram Singh',
        branch: 'CSE',
        year: '4th Year',
        headline: 'Cybersecurity • CTF player',
        location: 'Hyderabad, Telangana',
        about:
            'I play CTFs and love breaking (ethical) things. Can teach Linux, networking and basic pentesting.',
        teach: ['Cybersecurity', 'Linux', 'Networking'],
        learn: ['Machine Learning', 'UI Design'],
        experience: [
          Entry('Security Intern', 'SecureLayer • 2 months',
              'Assisted in web app vulnerability assessments.'),
        ],
        projects: [
          Entry('Port Scanner', 'Python • Sockets'),
        ],
        endorsements: _endo({'Cybersecurity': 12, 'Linux': 10, 'Networking': 7}),
        demo: true,
        done: 6,
        ratingSum: 29,
        ratingN: 6,
      ),
      Student(
        id: 'demo12@college.ac.in',
        name: 'Lakshmi Prasad',
        branch: 'MBA',
        year: '1st Year',
        headline: 'Finance & marketing • Startup enthusiast',
        location: 'Hyderabad, Telangana',
        about:
            'Looking to understand tech better. Can teach financial modelling and digital marketing basics.',
        teach: ['Financial Modelling', 'Digital Marketing', 'Excel'],
        learn: ['SQL', 'Web Development'],
        experience: [
          Entry('Marketing Intern', 'GrowthBox • 3 months',
              'Ran paid campaigns with 3x ROI.'),
        ],
        projects: [
          Entry('Startup Pitch Deck', 'Business Plan',
              'Runner-up at the B-school pitch contest.'),
        ],
        endorsements: _endo(
            {'Financial Modelling': 8, 'Digital Marketing': 9, 'Excel': 10}),
        demo: true,
        done: 3,
        ratingSum: 14,
        ratingN: 3,
      ),
    ];

// ============================================================
// APP STATE (persisted with SharedPreferences)
// ============================================================

String _hash(String s) => sha256.convert(utf8.encode(s)).toString();
int _now() => DateTime.now().millisecondsSinceEpoch;

class AppState extends ChangeNotifier {
  late final SharedPreferences _p;
  final Map<String, Student> students = {};
  final Map<String, String> _pw = {};
  final List<Swap> requests = [];
  String? _uid;

  Student? get me => _uid == null ? null : students[_uid];

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final s = _p.getString('students');
    if (s == null) {
      for (final st in _seedStudents()) {
        students[st.id] = st;
        _pw[st.id] = _hash('demo123');
      }
    } else {
      (jsonDecode(s) as Map<String, dynamic>).forEach((k, v) =>
          students[k] = Student.fromJson(Map<String, dynamic>.from(v)));
      _pw.addAll(Map<String, String>.from(jsonDecode(_p.getString('pw') ?? '{}')));
      final r = _p.getString('requests');
      if (r != null) {
        requests.addAll((jsonDecode(r) as List)
            .map((e) => Swap.fromJson(Map<String, dynamic>.from(e))));
      }
    }
    final uid = _p.getString('uid');
    if (uid != null && students.containsKey(uid)) _uid = uid;
  }

  void _commit() {
    _p.setString('students',
        jsonEncode(students.map((k, v) => MapEntry(k, v.toJson()))));
    _p.setString('pw', jsonEncode(_pw));
    _p.setString('requests', jsonEncode(requests.map((e) => e.toJson()).toList()));
    if (_uid == null) {
      _p.remove('uid');
    } else {
      _p.setString('uid', _uid!);
    }
    notifyListeners();
  }

  // ---------- auth ----------
  String? login(String rawEmail, String password) {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || password.isEmpty) return 'Enter email and password.';
    if (!students.containsKey(email)) {
      return 'No account found. Please sign up first.';
    }
    if (_pw[email] != _hash(password)) return 'Incorrect password.';
    _uid = email;
    _commit();
    return null;
  }

  String? register(String rawEmail, String password, String name, String branch,
      String year) {
    final email = rawEmail.trim().toLowerCase();
    if (name.trim().isEmpty) return 'Enter your name.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email.';
    }
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (students.containsKey(email)) return 'Account already exists. Please log in.';
    students[email] = Student(
      id: email,
      name: name.trim(),
      branch: branch,
      year: year,
      headline: '$branch student • $year',
      location: 'Telangana, India',
      about: '',
    );
    _pw[email] = _hash(password);
    _uid = email;
    _commit();
    return null;
  }

  void logout() {
    _uid = null;
    _commit();
  }

  // ---------- matching ----------
  bool _has(List<String> l, String s) =>
      l.any((e) => e.toLowerCase() == s.toLowerCase());

  /// Skills [o] can teach me.
  List<String> teachesMe(Student o) =>
      o.teach.where((s) => _has(me!.learn, s)).toList();

  /// Skills I can teach [o].
  List<String> learnsFromMe(Student o) =>
      me!.teach.where((s) => _has(o.learn, s)).toList();

  int score(Student o) =>
      teachesMe(o).length * 2 + learnsFromMe(o).length * 2 +
      (teachesMe(o).isNotEmpty && learnsFromMe(o).isNotEmpty ? 2 : 0);

  List<Student> get others =>
      students.values.where((s) => s.id != _uid).toList();

  // ---------- requests ----------
  Swap? requestWith(String otherId) {
    for (final r in requests) {
      if (r.status != 'declined' &&
          ((r.from == _uid && r.to == otherId) ||
              (r.to == _uid && r.from == otherId))) {
        return r;
      }
    }
    return null;
  }

  int get pendingCount =>
      requests.where((r) => r.to == _uid && r.status == 'pending').length;

  List<Swap> get incoming => requests.where((r) => r.to == _uid).toList().reversed.toList();
  List<Swap> get outgoing => requests.where((r) => r.from == _uid).toList().reversed.toList();

  int exchangesOf(String id) =>
      students[id]!.done +
      requests.where((r) => r.status == 'accepted' && (r.from == id || r.to == id) && !r.completed).length;

  void sendRequest(Student to, String wanted, String offered, String msg) {
    final r = Swap(
      id: '${_now()}',
      from: _uid!,
      to: to.id,
      wanted: wanted,
      offered: offered,
      message: msg,
      createdAt: _now(),
    );
    requests.add(r);
    _commit();
    if (to.demo) {
      Timer(const Duration(seconds: 3), () {
        if (r.status != 'pending') return;
        r.status = 'accepted';
        r.msgs.add(Msg(to.id,
            'Hi! Happy to swap ${r.offered.isEmpty ? 'skills' : r.offered} for ${r.wanted}. When are you free this week?',
            _now()));
        _commit();
      });
    }
  }

  void respond(Swap r, bool accept) {
    r.status = accept ? 'accepted' : 'declined';
    _commit();
  }

  void cancel(Swap r) {
    requests.remove(r);
    _commit();
  }

  static const _botReplies = [
    'Sounds good! How about this weekend?',
    'Great, I can do evenings after 6 PM.',
    'Let us meet in the library, it is quiet there.',
    'Perfect. I will share some starter material.',
    'Nice! Let us start with the basics first.',
  ];

  void sendMsg(Swap r, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    r.msgs.add(Msg(_uid!, t, _now()));
    _commit();
    final other = students[r.from == _uid ? r.to : r.from]!;
    if (other.demo) {
      Timer(const Duration(milliseconds: 1600), () {
        r.msgs.add(Msg(other.id, _botReplies[r.msgs.length % _botReplies.length], _now()));
        _commit();
      });
    }
  }

  void completeAndRate(Swap r, int stars) {
    final other = students[r.from == _uid ? r.to : r.from]!;
    if (!r.completed) {
      r.completed = true;
      me!.done++;
      other.done++;
    }
    if (!r.ratings.containsKey(_uid)) {
      r.ratings[_uid!] = stars;
      other.ratingSum += stars;
      other.ratingN++;
    }
    _commit();
  }

  // ---------- profile editing ----------
  void updateProfile(
      {String? name, String? headline, String? location, String? about, String? branch, String? year}) {
    final m = me!;
    if (name != null && name.isNotEmpty) m.name = name;
    if (headline != null) m.headline = headline;
    if (location != null) m.location = location;
    if (about != null) m.about = about;
    if (branch != null && branch.isNotEmpty) m.branch = branch;
    if (year != null && year.isNotEmpty) m.year = year;
    _commit();
  }

  void addSkill(bool teaching, String skill) {
    final v = skill.trim();
    if (v.isEmpty) return;
    final l = teaching ? me!.teach : me!.learn;
    if (_has(l, v)) return;
    l.add(v);
    _commit();
  }

  void removeSkill(bool teaching, String skill) {
    (teaching ? me!.teach : me!.learn).remove(skill);
    if (teaching) me!.endorsements.remove(skill);
    _commit();
  }

  void addEntry(bool project, Entry e) {
    (project ? me!.projects : me!.experience).add(e);
    _commit();
  }

  void removeEntry(bool project, Entry e) {
    (project ? me!.projects : me!.experience).remove(e);
    _commit();
  }

  void toggleEndorse(Student s, String skill) {
    final l = s.endorsements.putIfAbsent(skill, () => []);
    l.contains(_uid) ? l.remove(_uid) : l.add(_uid!);
    _commit();
  }
}

final AppState app = AppState();

// ============================================================
// APP
// ============================================================

const kBlue = Color(0xFF0A66C2);
const kBg = Color(0xFFF3F2EF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await app.init();

  runApp(const SkillApp());
}

class SkillApp extends StatelessWidget {
  const SkillApp({super.key});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return MaterialApp(
      title: 'Skill Exchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0DFDC)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: b(const Color(0xFFD0D0D0)),
          enabledBorder: b(const Color(0xFFD0D0D0)),
          focusedBorder: b(kBlue, 2),
        ),
      ),
      home: ListenableBuilder(
        listenable: app,
        builder: (_, __) =>
            app.me == null ? const AuthScreen() : const HomeShell(),
      ),
    );
  }
}

// ============================================================
// SHARED HELPERS / WIDGETS
// ============================================================

Color _colorFor(String s) {
  const cs = [
    Color(0xFF0A66C2), Color(0xFF7A3FB4), Color(0xFFC2410C), Color(0xFF0F766E),
    Color(0xFFBE185D), Color(0xFF4D7C0F), Color(0xFF9333EA), Color(0xFF0369A1),
  ];
  return cs[s.codeUnits.fold<int>(0, (a, b) => a + b) % cs.length];
}

String _time(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class Avatar extends StatelessWidget {
  final String name;
  final double radius;
  const Avatar(this.name, {super.key, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _colorFor(name),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

class SkillChip extends StatelessWidget {
  final String label;
  final bool highlight;
  final VoidCallback? onDelete;
  const SkillChip(this.label, {super.key, this.highlight = false, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = highlight ? const Color(0xFF057642) : kBlue;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 6, onDelete == null ? 12 : 6, 6),
      decoration: BoxDecoration(
        color: c.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13)),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDelete,
              child: Icon(Icons.close, size: 16, color: c),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onAdd;
  const SectionCard({super.key, required this.title, required this.child, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  if (onAdd != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_circle_outline, color: kBlue),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(text, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
}

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(m)));

/// Generic multi-field dialog. Returns trimmed values, or null if cancelled.
Future<List<String>?> showForm(
  BuildContext context,
  String title,
  List<String> labels, {
  List<String>? initial,
  List<int>? lines,
  String action = 'Save',
}) =>
    showDialog<List<String>>(
      context: context,
      builder: (_) => _FormDialog(title, labels, initial, lines, action),
    );

class _FormDialog extends StatefulWidget {
  final String title, action;
  final List<String> labels;
  final List<String>? initial;
  final List<int>? lines;
  const _FormDialog(this.title, this.labels, this.initial, this.lines, this.action);

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  late final ctrls = List.generate(
    widget.labels.length,
    (i) => TextEditingController(text: widget.initial?[i] ?? ''),
  );

  @override
  void dispose() {
    for (final c in ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < ctrls.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                child: TextField(
                  controller: ctrls[i],
                  autofocus: i == 0,
                  maxLines: widget.lines?[i] ?? 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: widget.labels[i]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, ctrls.map((c) => c.text.trim()).toList()),
          child: Text(widget.action),
        ),
      ],
    );
  }
}

// ============================================================
// AUTH
// ============================================================

const kBranches = ['CSE', 'CSE (AIML)', 'IT', 'ECE', 'EEE', 'Mechanical', 'Civil', 'MBA', 'Other'];
const kYears = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  bool isLogin = true, hide = true;
  String branch = kBranches.first, year = kYears.first;
  String? error;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    name.dispose();
    super.dispose();
  }

  void submit() {
    FocusScope.of(context).unfocus();
    final err = isLogin
        ? app.login(email.text, pass.text)
        : app.register(email.text, pass.text, name.text, branch, year);
    if (err != null) setState(() => error = err);
  }

  void fillDemo() => setState(() {
        isLogin = true;
        email.text = 'demo1@college.ac.in';
        pass.text = 'demo123';
        error = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: kBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text('Skill Exchange',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  Text('Learn • Teach • Connect',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isLogin ? 'Sign in' : 'Join your campus network',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          if (!isLogin) ...[
                            TextField(
                              controller: name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  prefixIcon: Icon(Icons.person_outline)),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                                labelText: 'College email',
                                prefixIcon: Icon(Icons.school_outlined)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: pass,
                            obscureText: hide,
                            onSubmitted: (_) => submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => hide = !hide),
                                icon: Icon(hide
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                              ),
                            ),
                          ),
                          if (!isLogin) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: branch,
                              decoration: const InputDecoration(labelText: 'Branch'),
                              items: kBranches
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => branch = v!),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: year,
                              decoration: const InputDecoration(labelText: 'Year'),
                              items: kYears
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => year = v!),
                            ),
                          ],
                          if (error != null) ...[
                            const SizedBox(height: 12),
                            Text(error!, style: TextStyle(color: Colors.red.shade700)),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: submit,
                              child: Text(isLogin ? 'Sign in' : 'Create account',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() {
                                isLogin = !isLogin;
                                error = null;
                              }),
                              child: Text(isLogin
                                  ? 'New here? Join now'
                                  : 'Already a member? Sign in'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: fillDemo,
                    icon: const Icon(Icons.bolt),
                    label: const Text('Fill demo login (demo1 / demo123)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME SHELL
// ============================================================

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final me = app.me;
        if (me == null) return const SizedBox.shrink();
        final pending = app.pendingCount;
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              const DiscoverScreen(),
              const RequestsScreen(),
              ProfileScreen(id: me.id, root: true),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.white,
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Network',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending'),
                  child: const Icon(Icons.swap_horiz),
                ),
                label: 'Exchanges',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Me',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// DISCOVER
// ============================================================

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String query = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final me = app.me!;
        final q = query.toLowerCase().trim();
        final all = app.others;
        final branches = {for (final s in all) s.branch}.toList()..sort();

        final list = all.where((s) {
          if (filter == 'Matches' && app.score(s) == 0) return false;
          if (filter != 'All' && filter != 'Matches' && s.branch != filter) return false;
          if (q.isEmpty) return true;
          return s.name.toLowerCase().contains(q) ||
              s.branch.toLowerCase().contains(q) ||
              s.headline.toLowerCase().contains(q) ||
              s.teach.any((t) => t.toLowerCase().contains(q));
        }).toList()
          ..sort((a, b) {
            final c = app.score(b).compareTo(app.score(a));
            return c != 0 ? c : (b.rating ?? 0).compareTo(a.rating ?? 0);
          });

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            title: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'Search people, skills, branches',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.zero,
                  fillColor: const Color(0xFFEDF3F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ProfileScreen(id: me.id))),
                  child: Avatar(me.name, radius: 17),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (final f in ['All', 'Matches', ...branches])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: filter == f,
                          onSelected: (_) => setState(() => filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(Icons.search_off, 'No students found.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => StudentCard(student: list[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StudentCard extends StatelessWidget {
  final Student student;
  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final s = student;
    final gives = app.teachesMe(s);
    final gets = app.learnsFromMe(s);
    final r = app.requestWith(s.id);

    String? matchText;
    if (gives.isNotEmpty && gets.isNotEmpty) {
      matchText = 'Mutual match • teaches ${gives.first}, wants ${gets.first}';
    } else if (gives.isNotEmpty) {
      matchText = 'Can teach you ${gives.join(', ')}';
    } else if (gets.isNotEmpty) {
      matchText = 'Wants to learn ${gets.join(', ')} from you';
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => ProfileScreen(id: s.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(s.name, radius: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(s.headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('${s.branch} • ${s.year}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        if (s.rating != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 15, color: Color(0xFFE7A33E)),
                                const SizedBox(width: 3),
                                Text(
                                  '${s.rating!.toStringAsFixed(1)} (${s.ratingN})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (matchText != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF057642)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(matchText,
                          style: const TextStyle(
                              color: Color(0xFF057642),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in s.teach.take(4))
                    SkillChip(t, highlight: gives.contains(t)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: r == null
                    ? OutlinedButton.icon(
                        onPressed: () => showRequestDialog(context, s),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Exchange'),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          foregroundColor: kBlue,
                          side: const BorderSide(color: kBlue),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                        child: Text(r.status == 'accepted'
                            ? 'Connected'
                            : r.from == app.me!.id
                                ? 'Request sent'
                                : 'Wants to connect'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showRequestDialog(BuildContext context, Student s) async {
  final gives = app.teachesMe(s);
  final gets = app.learnsFromMe(s);
  final v = await showForm(
    context,
    'Exchange with ${s.name}',
    ['Skill you want to learn', 'Skill you can teach', 'Message'],
    initial: [
      gives.isNotEmpty ? gives.first : (s.teach.isNotEmpty ? s.teach.first : ''),
      gets.isNotEmpty ? gets.first : (app.me!.teach.isNotEmpty ? app.me!.teach.first : ''),
      'Hi ${s.name.split(' ').first}, I would love to swap skills with you!',
    ],
    lines: [1, 1, 3],
    action: 'Send',
  );
  if (v == null || !context.mounted) return;
  if (v[0].isEmpty) {
    toast(context, 'Please enter the skill you want to learn.');
    return;
  }
  app.sendRequest(s, v[0], v[1], v[2]);
  toast(context, 'Exchange request sent to ${s.name}.');
}

// ============================================================
// PROFILE (LinkedIn style) — used for me and for others
// ============================================================

class ProfileScreen extends StatelessWidget {
  final String id;
  final bool root;
  const ProfileScreen({super.key, required this.id, this.root = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final s = app.students[id];
        final me = app.me;
        if (s == null || me == null) return const SizedBox.shrink();
        final isMe = s.id == me.id;
        final base = _colorFor(s.name);
        final req = isMe ? null : app.requestWith(s.id);
        final gives = isMe ? <String>[] : app.teachesMe(s);

        return Scaffold(
          appBar: AppBar(
            title: Text(isMe ? 'My Profile' : 'Profile',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              if (isMe && root)
                IconButton(
                  tooltip: 'Log out',
                  icon: const Icon(Icons.logout),
                  onPressed: app.logout,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Header card
              Card(
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [base, base.withAlpha(120)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          bottom: -40,
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white,
                            child: Avatar(s.name, radius: 42),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(s.name,
                                    style: const TextStyle(
                                        fontSize: 22, fontWeight: FontWeight.w800)),
                              ),
                              if (isMe)
                                IconButton(
                                  onPressed: () => _editProfile(context, s),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                            ],
                          ),
                          if (s.headline.isNotEmpty)
                            Text(s.headline, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            '${s.branch} • ${s.year}${s.location.isEmpty ? '' : ' • ${s.location}'}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(s.id,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text('${app.exchangesOf(s.id)} exchanges',
                                  style: const TextStyle(
                                      color: kBlue, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 14),
                              const Icon(Icons.star, size: 16, color: Color(0xFFE7A33E)),
                              const SizedBox(width: 3),
                              Text(s.rating == null
                                  ? 'New'
                                  : '${s.rating!.toStringAsFixed(1)} (${s.ratingN})'),
                            ],
                          ),
                          if (!isMe) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: req == null
                                      ? FilledButton.icon(
                                          onPressed: () => showRequestDialog(context, s),
                                          icon: const Icon(Icons.swap_horiz),
                                          label: const Text('Exchange skills'),
                                          style: FilledButton.styleFrom(
                                              shape: const StadiumBorder()),
                                        )
                                      : req.status == 'accepted'
                                          ? FilledButton.icon(
                                              onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          ExchangeScreen(swap: req))),
                                              icon: const Icon(Icons.chat_bubble_outline),
                                              label: const Text('Message'),
                                              style: FilledButton.styleFrom(
                                                  shape: const StadiumBorder()),
                                            )
                                          : OutlinedButton(
                                              onPressed: null,
                                              style: OutlinedButton.styleFrom(
                                                  shape: const StadiumBorder()),
                                              child: Text(req.from == me.id
                                                  ? 'Request pending'
                                                  : 'Respond in Exchanges tab'),
                                            ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // About
              if (s.about.isNotEmpty || isMe)
                SectionCard(
                  title: 'About',
                  child: Text(
                    s.about.isEmpty
                        ? 'Tell classmates about yourself (tap the pencil above).'
                        : s.about,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                  ),
                ),

              // Skills with endorsements
              SectionCard(
                title: 'Skills I can teach',
                onAdd: isMe ? () => _addSkill(context, true) : null,
                child: s.teach.isEmpty
                    ? Text('No skills added yet.',
                        style: TextStyle(color: Colors.grey.shade600))
                    : Column(
                        children: [
                          for (final t in s.teach)
                            _EndorseRow(student: s, skill: t, isMe: isMe,
                                matched: gives.contains(t)),
                        ],
                      ),
              ),
              SectionCard(
                title: 'Wants to learn',
                onAdd: isMe ? () => _addSkill(context, false) : null,
                child: s.learn.isEmpty
                    ? Text('No skills added yet.',
                        style: TextStyle(color: Colors.grey.shade600))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final l in s.learn)
                            SkillChip(l,
                                onDelete: isMe ? () => app.removeSkill(false, l) : null),
                        ],
                      ),
              ),

              // Experience & projects
              if (s.experience.isNotEmpty || isMe)
                _EntrySection(
                  title: 'Experience',
                  icon: Icons.work_outline,
                  entries: s.experience,
                  editable: isMe,
                  onAdd: () => _addEntry(context, false),
                  onDelete: (e) => app.removeEntry(false, e),
                ),
              if (s.projects.isNotEmpty || isMe)
                _EntrySection(
                  title: 'Projects',
                  icon: Icons.rocket_launch_outlined,
                  entries: s.projects,
                  editable: isMe,
                  onAdd: () => _addEntry(context, true),
                  onDelete: (e) => app.removeEntry(true, e),
                ),

              // Education
              SectionCard(
                title: 'Education',
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: kBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance, color: kBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('B.Tech / Undergraduate Program',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('${s.branch} • ${s.year}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editProfile(BuildContext context, Student s) async {
    final v = await showForm(
      context,
      'Edit profile',
      ['Name', 'Headline', 'Branch', 'Year', 'Location', 'About'],
      initial: [s.name, s.headline, s.branch, s.year, s.location, s.about],
      lines: [1, 2, 1, 1, 1, 4],
    );
    if (v == null) return;
    app.updateProfile(
        name: v[0], headline: v[1], branch: v[2], year: v[3], location: v[4], about: v[5]);
  }

  Future<void> _addSkill(BuildContext context, bool teaching) async {
    final v = await showForm(
      context,
      teaching ? 'Add teaching skill' : 'Add learning skill',
      ['Skill (e.g. Flutter, SQL)'],
      action: 'Add',
    );
    if (v != null) app.addSkill(teaching, v[0]);
  }

  Future<void> _addEntry(BuildContext context, bool project) async {
    final v = await showForm(
      context,
      project ? 'Add project' : 'Add experience',
      project
          ? ['Project title', 'Tech / tools', 'Description']
          : ['Role', 'Organisation • duration', 'Description'],
      lines: [1, 1, 3],
      action: 'Add',
    );
    if (v != null && v[0].isNotEmpty) app.addEntry(project, Entry(v[0], v[1], v[2]));
  }
}

class _EndorseRow extends StatelessWidget {
  final Student student;
  final String skill;
  final bool isMe, matched;
  const _EndorseRow({
    required this.student,
    required this.skill,
    required this.isMe,
    required this.matched,
  });

  @override
  Widget build(BuildContext context) {
    final list = student.endorsements[skill] ?? const [];
    final mine = list.contains(app.me!.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(skill,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    if (matched) ...[
                      const SizedBox(width: 8),
                      const SkillChip('You want this', highlight: true),
                    ],
                  ],
                ),
                Text('${list.length} endorsement${list.length == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
              ],
            ),
          ),
          if (isMe)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => app.removeSkill(true, skill),
              icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
            )
          else
            OutlinedButton.icon(
              onPressed: () => app.toggleEndorse(student, skill),
              icon: Icon(mine ? Icons.thumb_up : Icons.thumb_up_outlined, size: 16),
              label: Text(mine ? 'Endorsed' : 'Endorse'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: const StadiumBorder(),
                foregroundColor: mine ? const Color(0xFF057642) : kBlue,
              ),
            ),
        ],
      ),
    );
  }
}

class _EntrySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Entry> entries;
  final bool editable;
  final VoidCallback onAdd;
  final void Function(Entry) onDelete;
  const _EntrySection({
    required this.title,
    required this.icon,
    required this.entries,
    required this.editable,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      onAdd: editable ? onAdd : null,
      child: entries.isEmpty
          ? Text('Nothing added yet.', style: TextStyle(color: Colors.grey.shade600))
          : Column(
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                              if (e.sub.isNotEmpty)
                                Text(e.sub,
                                    style: TextStyle(color: Colors.grey.shade700)),
                              if (e.desc.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(e.desc,
                                      style: TextStyle(
                                          color: Colors.grey.shade800, height: 1.4)),
                                ),
                            ],
                          ),
                        ),
                        if (editable)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => onDelete(e),
                            icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ============================================================
// REQUESTS
// ============================================================

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final inc = app.incoming;
          final out = app.outgoing;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Exchanges',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Received (${inc.length})'),
                  Tab(text: 'Sent (${out.length})'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _SwapList(items: inc, incoming: true),
                _SwapList(items: out, incoming: false),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SwapList extends StatelessWidget {
  final List<Swap> items;
  final bool incoming;
  const _SwapList({required this.items, required this.incoming});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        incoming ? Icons.inbox_outlined : Icons.send_outlined,
        incoming ? 'No incoming requests yet.' : 'You have not sent any requests.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => SwapCard(swap: items[i], incoming: incoming),
    );
  }
}

class SwapCard extends StatelessWidget {
  final Swap swap;
  final bool incoming;
  const SwapCard({super.key, required this.swap, required this.incoming});

  @override
  Widget build(BuildContext context) {
    final other = app.students[incoming ? swap.from : swap.to];
    if (other == null) return const SizedBox.shrink();
    final st = swap.status;
    final color = st == 'accepted'
        ? const Color(0xFF057642)
        : st == 'declined'
            ? Colors.red.shade700
            : Colors.orange.shade800;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(id: other.id))),
              child: Row(
                children: [
                  Avatar(other.name, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(other.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(other.headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      swap.completed ? 'Completed' : st[0].toUpperCase() + st.substring(1),
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Side(label: incoming ? 'They want' : 'You want', skill: swap.wanted)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz, color: kBlue),
                ),
                Expanded(child: _Side(label: incoming ? 'They offer' : 'You offer', skill: swap.offered.isEmpty ? '—' : swap.offered)),
              ],
            ),
            if (swap.message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('“${swap.message}”',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey.shade800)),
            ],
            const SizedBox(height: 12),
            if (incoming && st == 'pending')
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => app.respond(swap, true),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => app.respond(swap, false),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            if (!incoming && st == 'pending')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => app.cancel(swap),
                  child: const Text('Withdraw request'),
                ),
              ),
            if (st == 'accepted')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ExchangeScreen(swap: swap))),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(swap.msgs.isEmpty
                      ? 'Start chatting'
                      : 'Open chat (${swap.msgs.length})'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final String label, skill;
  const _Side({required this.label, required this.skill});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(skill, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

// ============================================================
// EXCHANGE CHAT
// ============================================================

class ExchangeScreen extends StatefulWidget {
  final Swap swap;
  const ExchangeScreen({super.key, required this.swap});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final input = TextEditingController();

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void send() {
    app.sendMsg(widget.swap, input.text);
    input.clear();
  }

  Future<void> rate() async {
    int stars = 5;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Mark completed & rate'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setS(() => stars = i),
                  icon: Icon(i <= stars ? Icons.star : Icons.star_border,
                      color: const Color(0xFFE7A33E), size: 32),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (ok == true) {
      app.completeAndRate(widget.swap, stars);
      if (mounted) toast(context, 'Thanks for rating!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final r = widget.swap;
        final me = app.me!;
        final other = app.students[r.from == me.id ? r.to : r.from]!;
        final rated = r.ratings.containsKey(me.id);
        final msgs = r.msgs.reversed.toList();

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(id: other.id))),
              child: Row(
                children: [
                  Avatar(other.name, radius: 17),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(other.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            actions: [
              if (!rated)
                TextButton.icon(
                  onPressed: rate,
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: Text(r.completed ? 'Rate' : 'Complete'),
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  r.from == me.id
                      ? 'You learn ${r.wanted}  ⇄  You teach ${r.offered.isEmpty ? '—' : r.offered}'
                      : 'You teach ${r.wanted}  ⇄  You learn ${r.offered.isEmpty ? '—' : r.offered}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Expanded(
                child: msgs.isEmpty
                    ? const EmptyState(Icons.chat_outlined,
                        'Say hello and plan your first session!')
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) {
                          final m = msgs[i];
                          final mine = m.from == me.id;
                          return Align(
                            alignment:
                                mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75),
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: mine ? kBlue : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: mine
                                    ? null
                                    : Border.all(color: const Color(0xFFE0DFDC)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(m.text,
                                      style: TextStyle(
                                          color: mine ? Colors.white : Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text(_time(m.time),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: mine
                                              ? Colors.white70
                                              : Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          onSubmitted: (_) => send(),
                          textInputAction: TextInputAction.send,
                          decoration: const InputDecoration(
                            hintText: 'Write a message…',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: send,
                        icon: const Icon(Icons.send, color: kBlue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

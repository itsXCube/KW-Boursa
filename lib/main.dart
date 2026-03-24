import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const BoursaApp());
}

class BoursaApp extends StatelessWidget {
  const BoursaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بورصة الكويت',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'KW'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC8A84B),
          secondary: Color(0xFFE8C96A),
          surface: Color(0xFF111E36),
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F2044),
          foregroundColor: const Color(0xFFE8C96A),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 17, fontWeight: FontWeight.w700,
            color: const Color(0xFFE8C96A),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFC8A84B)),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF111E36),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E3358)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

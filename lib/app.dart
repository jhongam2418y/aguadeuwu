import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/configuracion/presentation/providers/config_provider.dart';
import 'features/tickets/presentation/providers/ticket_provider.dart';
import 'features/tickets/presentation/screens/dashboard_screen.dart';

class PiscigranjaApp extends StatelessWidget {
  const PiscigranjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigProvider()..cargar()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: MaterialApp(
        title: 'Piscigranja — Boletería',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF003D99),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:gap/gap.dart';
import 'dart:io';
import 'dart:async';

class ScreenTimeCard extends StatefulWidget {
  const ScreenTimeCard({super.key});

  @override
  State<ScreenTimeCard> createState() => _ScreenTimeCardState();
}

class _ScreenTimeCardState extends State<ScreenTimeCard> with WidgetsBindingObserver {
  String _duration = "0h 0m";
  bool _isLoading = true;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    // Monitorizăm când aplicația este pusă în fundal sau revine
    WidgetsBinding.instance.addObserver(this);
    _fetchScreenTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Actualizăm doar când utilizatorul revine în aplicație (Resumed)
    if (state == AppLifecycleState.resumed) {
      _fetchScreenTime(force: true);
    }
  }

  Future<void> _fetchScreenTime({bool force = false}) async {
    if (!Platform.isAndroid) return;

    // OPTIMIZARE RESURSE:
    // Nu interogăm sistemul mai des de o dată la 2 minute,
    // decât dacă este forțat (ex: la deschiderea aplicației)
    if (!force && _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 2) {
      return;
    }

    try {
      bool? isPermissionGranted = await UsageStats.checkUsagePermission();
      if (isPermissionGranted == false) {
        // Nu forțăm setările aici pentru a nu strica experiența utilizatorului
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);

      // Interogarea evenimentelor
      List<EventUsageInfo> events = await UsageStats.queryEvents(startOfDay, now);
      if (events.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Sortare eficientă
      events.sort((a, b) => a.timeStamp!.compareTo(b.timeStamp!));

      int totalTimeMs = 0;
      int? sessionStartTime;

      for (var event in events) {
        int timestamp = int.parse(event.timeStamp!);
        String pkg = event.packageName ?? "";

        // LISTA NEAGRĂ (Filtrare SystemUI și Launchere pentru precizie)
        bool isSystemExcluded = pkg.contains("com.android.systemui") ||
            pkg.contains("launcher");

        if (event.eventType == "1") { // MOVE_TO_FOREGROUND
          if (!isSystemExcluded) {
            sessionStartTime ??= timestamp;
          } else {
            if (sessionStartTime != null) {
              totalTimeMs += (timestamp - sessionStartTime);
              sessionStartTime = null;
            }
          }
        } else if (event.eventType == "2") { // MOVE_TO_BACKGROUND
          if (sessionStartTime != null) {
            totalTimeMs += (timestamp - sessionStartTime);
            sessionStartTime = null;
          }
        }
      }

      // Adăugăm sesiunea curentă
      if (sessionStartTime != null) {
        totalTimeMs += (now.millisecondsSinceEpoch - sessionStartTime);
      }

      if (mounted) {
        setState(() {
          _lastFetchTime = DateTime.now();
          Duration d = Duration(milliseconds: totalTimeMs);
          _duration = "${d.inHours}h ${d.inMinutes.remainder(60)}m";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withRed(100)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: _isLoading
          ? const Center(child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
      ))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
              const Gap(8),
              Text(
                "Timpul de ecran de azi",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            _duration,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const Gap(4),
          Row(
            children: [
              Icon(
                  Icons.check_circle_outline,
                  color: Colors.white.withOpacity(0.5),
                  size: 12
              ),
              const Gap(4),
              Text(
                "Sincronizat live",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
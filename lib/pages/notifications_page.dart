import 'package:Laovista/pages/models/announcement.dart';
import 'package:Laovista/pages/models/event.dart';
import 'package:Laovista/pages/notification_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  final List<Announcement> announcements;
  final List<Event> events;

  const NotificationsPage({
    Key? key,
    required this.announcements,
    required this.events,
  }) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> items = [];
  Set<String> readNotifications = {};
  final now = DateTime.now();

  bool showAll = false;
  final int initialDisplayCount = 5;

  @override
  void initState() {
    super.initState();
    loadReadNotifications().then((_) => buildNotificationList());
  }

  Future<void> loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('readNotifications');
    if (saved != null) readNotifications = saved.toSet();
    setState(() {});
  }

  Future<void> markAsRead(String id) async {
    readNotifications.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('readNotifications', readNotifications.toList());
    setState(() {});
  }

  void buildNotificationList() {
    items = [
      ...widget.announcements.map((a) => {
            'id': a.title ?? DateTime.now().toIso8601String(),
            'type': 'announcement',
            'title': a.title ?? 'No Title',
            'details': a.details ?? '',
            'images': a.images ?? [],
            'listDate': (DateTime.tryParse(a.createdAt ?? a.date) ?? DateTime.now()).toLocal(),
            'scheduledDate': (a.date != null) ? DateTime.parse(a.date!).toLocal() : DateTime.now(),
          }),
      ...widget.events.where((e) => e.status == 'approved').map((e) => {
            'id': e.title ?? DateTime.now().toIso8601String(),
            'type': 'event',
            'title': e.title ?? 'No Title',
            'details': e.details ?? '',
            'images': e.images ?? [],
            'listDate': (DateTime.tryParse(e.updatedDate ?? e.date) ?? DateTime.now()).toLocal(),
            'scheduledDate': (e.date != null) ? DateTime.parse(e.date!).toLocal() : DateTime.now(),
          }),
    ];

    items.sort((a, b) => (b['listDate'] as DateTime).compareTo(a['listDate'] as DateTime));
    setState(() {});
  }

  Future<void> _refreshNotifications() async {
    buildNotificationList();
  }

  @override
Widget build(BuildContext context) {
  final displayItems = showAll ? items : items.take(initialDisplayCount).toList();

  return Scaffold(
    // Keep AppBar normal
    appBar: AppBar(
      title: const Text(
        'Notifications',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue.shade800,
      elevation: 0,
    ),
    body: Container(
      // Gradient background for entire body
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade200, // top
            Colors.blue.shade50,  // bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: items.isEmpty
          ? const Center(
              child: Text(
                "No new notifications",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: displayItems.length + (items.length > initialDisplayCount ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displayItems.length && items.length > initialDisplayCount) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () => setState(() => showAll = !showAll),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue.shade800,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.blue.shade800),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          showAll ? "See Less" : "See More",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }

                  final item = displayItems[index];
                  final type = item['type'] as String;
                  final id = item['id'] as String;
                  final listDate = item['listDate'] as DateTime;
                  final scheduledDate = item['scheduledDate'] as DateTime;
                  final isNew = !readNotifications.contains(id) && now.difference(listDate).inHours < 24;

                 final formattedListDate = DateFormat('MMMM d, yyyy • h:mm a').format(listDate);


                  final iconData = type == 'announcement' ? Icons.campaign_rounded : Icons.event_note_rounded;
                  final iconColor = type == 'announcement' ? Colors.orange.shade700 : Colors.green.shade700;
                  final iconBackground = type == 'announcement' ? Colors.orange.shade50 : Colors.green.shade50;

                  return GestureDetector(
                    onTap: () async {
                      await markAsRead(id);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationDetailPage(
                            title: item['title'] as String,
                            details: item['details'] as String,
                            date: DateFormat('MMMM d, yyyy • h:mm a').format(scheduledDate),
                            type: type,
                            images: (item['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isNew ? Colors.yellow[50] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border(
                          left: BorderSide(
                            color: isNew
                                ? (type == 'announcement' ? Colors.orange.shade400 : Colors.green.shade400)
                                : Colors.grey.shade300,
                            width: 4,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        leading: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: iconBackground),
                          padding: const EdgeInsets.all(12),
                          child: Icon(iconData, color: iconColor, size: 28),
                        ),
                        title: Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          formattedListDate,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
    ),
  );
}
}
import 'package:Laovista/pages/models/announcement.dart';


List<Announcement> filterAnnouncementsForMyBarangay(
  List<Announcement> announcements,
  int myBarangayId,
) {
  return announcements.where((announcement) {
    if (announcement.target == 'all') {
      return true;
    } else if (announcement.target == 'specific' && announcement.barangayId == myBarangayId) {
      return true;
    } else {
      return false;
    }
  }).toList();
}

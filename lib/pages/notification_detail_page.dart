import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationDetailPage extends StatefulWidget {
  final String title;
  final String details;
  final String date;
  final String type;
  final List<String> images;

  const NotificationDetailPage({
    Key? key,
    required this.title,
    required this.details,
    required this.date,
    required this.type,
    this.images = const [],
  }) : super(key: key);

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  int _currentImageIndex = 0;

  void _showFullscreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image, color: Colors.white, size: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        widget.type == 'announcement' ? Colors.blue.shade700 : Colors.green.shade700;

   return Scaffold(
  backgroundColor: Colors.grey[100],
  appBar: AppBar(
    title: Text(
      widget.type == 'announcement' ? 'Announcement' : 'Barangay Events',
      style: const TextStyle(
        color: Colors.white, // <-- make text white
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: primaryColor,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(24),
      ),
    ),
  ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  widget.date,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                widget.details,
                style: const TextStyle(fontSize: 16, height: 1.6),
                textAlign: TextAlign.justify,
              ),
            ),
            // Images Section
            if (widget.images.isNotEmpty) ...[
              const SizedBox(height: 24),
            
           
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: widget.images.length,
                  controller: PageController(viewportFraction: 0.95),
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = widget.images[index];
                    return GestureDetector(
                      onTap: () => _showFullscreenImage(imageUrl),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image, size: 60),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == i ? 12 : 8,
                    height: _currentImageIndex == i ? 12 : 8,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == i ? primaryColor : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

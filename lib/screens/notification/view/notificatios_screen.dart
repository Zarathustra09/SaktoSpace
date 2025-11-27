import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shop/screens/order/views/orders_screen.dart';
import 'package:shop/constants.dart';
import 'package:intl/intl.dart';
import 'package:shop/services/notification/notification_service.dart';

// Helper class for detail items (moved outside State class)
class _DetailItem {
  final String label;
  final String value;
  final IconData icon;
  _DetailItem(this.label, this.value, this.icon);
}

// Notifications UI
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<NotificationModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _service.getAll();
    await _service.markAllAsRead();
    if (mounted) setState(() { _items = all; _loading = false; });
  }

  Future<void> _delete(int id) async {
    await _service.delete(id);
    _load();
  }

  Future<void> _deleteAll() async {
    await _service.deleteAll();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          // Deletion controls removed to prevent deleting notifications from UI
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You will see notifications here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      // Determine icon based on notification type
                      IconData iconData = Icons.notifications;
                      Color? iconColor;
                      if (n.data != null) {
                        try {
                          final d = jsonDecode(n.data!);
                          if (d['type'] == 'promotion') {
                            iconData = Icons.campaign;
                            iconColor = Colors.green;
                          } else if (d['type'] == 'order') {
                            iconData = Icons.shopping_bag;
                            iconColor = Colors.blue;
                          }
                        } catch (_) {}
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor?.withOpacity(0.1),
                          child: Icon(iconData, color: iconColor),
                        ),
                        title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(_ago(n.createdAt), style: Theme.of(context).textTheme.bodySmall),
                        onTap: () async {
                          // If notification contains JSON data with an order_id, navigate to OrdersScreen.
                          if (n.data != null) {
                            try {
                              final Map<String, dynamic> d = jsonDecode(n.data!);
                              final orderId = d['order_id'] ?? d['orderId'] ?? d['id'];
                              if (orderId != null) {
                                // Navigate to orders screen (you can extend OrdersScreen to accept an order id if needed)
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                                );
                                return;
                              }
                            } catch (_) {
                              // ignore JSON parse errors and fall back to detail view
                            }
                          }
                          // Default behaviour: show detail dialog (does not delete notification)
                          _showDetail(n);
                        },
                      );
                    },
                  ),
                )),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }

  void _showDetail(NotificationModel n) {
    // Logging
    print('=== NOTIFICATION DETAIL ===');
    print('Title: ${n.title}');
    print('Body: ${n.body}');
    print('Created At: ${n.createdAt}');
    print('Time Ago: ${_ago(n.createdAt)}');

    Map<String, dynamic>? data;
    String? type;
    try {
      if (n.data != null && n.data!.isNotEmpty) {
        data = jsonDecode(n.data!) as Map<String, dynamic>;
        type = data['type'] as String?;
        print('Type: $type');
      }
    } catch (e) {
      print('Parse error: $e');
    }
    print('=== END NOTIFICATION DETAIL ===');

    // Icon & color
    IconData icon = Icons.notifications;
    Color color = primaryColor;
    switch (type) {
      case 'order':
        icon = Icons.shopping_bag; color = Colors.blue;
        break;
      case 'promotion':
        icon = Icons.local_offer; color = successColor;
        break;
      case 'payment':
        icon = Icons.payment; color = warningColor;
        break;
      case 'delivery':
        icon = Icons.local_shipping; color = accentBlueColor;
        break;
    }

    // Extract details (label/value/icon)
    final details = <_DetailItem>[];
    if (data != null) {
      if (type == 'promotion') {
        if (data['start_date'] != null && data['end_date'] != null) {
          details.add(
            _DetailItem(
              'Valid Period',
              '${_formatDate(data['start_date'])} - ${_formatDate(data['end_date'])}',
              Icons.event,
            ),
          );
        }
        _addIf(details, 'Discount', data['discount'] != null ? '${data['discount']}% OFF' : null, Icons.discount);
        _addIf(details, 'Promo Code', data['code'], Icons.confirmation_number_outlined);
      } else if (type == 'order') {
        final orderId = data['order_id'] ?? data['orderId'];
        _addIf(details, 'Order ID', orderId != null ? '#$orderId' : null, Icons.receipt_long);
        _addIf(details, 'Status', data['status'] != null ? _capitalize(data['status']) : null, Icons.info_outline);
        final amt = data['amount'] ?? data['total'];
        _addIf(details, 'Amount', amt != null ? formatPeso(amt) : null, Icons.payments_outlined);
      } else if (type == 'payment') {
        _addIf(details, 'Transaction ID', data['transaction_id'], Icons.receipt);
        _addIf(details, 'Amount', data['amount'] != null ? formatPeso(data['amount']) : null, Icons.payments);
        _addIf(details, 'Method', data['method'] != null ? _capitalize(data['method']) : null, Icons.credit_card);
      } else if (type == 'delivery') {
        _addIf(details, 'Tracking Number', data['tracking_number'], Icons.local_shipping);
        _addIf(details, 'Status', data['status'] != null ? _capitalize(data['status']) : null, Icons.info_outline);
        _addIf(details, 'Estimated Delivery',
            data['estimated_delivery'] != null ? _formatDate(data['estimated_delivery']) : null,
            Icons.event);
      } else {
        // Generic fallback
        data.forEach((k, v) {
          if (k != 'type' && v != null) {
            details.add(_DetailItem(_capitalize(k.replaceAll('_', ' ')), v.toString(), Icons.info_outline));
          }
        });
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultBorderRadious)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                n.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDateTime(n.createdAt),
                      style: TextStyle(fontSize: 12, color: blackColor60)),
                  const SizedBox(height: 12),
                  if (type == 'promotion' && data?['image_url'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        data!['image_url'],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  if (type == 'promotion' && data?['image_url'] != null)
                    const SizedBox(height: 16),
                  Text(n.body, style: const TextStyle(fontSize: 14, height: 1.4)),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    ...details.map(_detailRow),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (type == 'order' && (data?['order_id'] != null || data?['orderId'] != null))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
              child: const Text('View Order'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper: add detail safely
  void _addIf(List<_DetailItem> list, String label, dynamic value, IconData icon) {
    if (value == null) return;
    list.add(_DetailItem(label, value.toString(), icon));
  }

  // Helper: detail row
  Widget _detailRow(_DetailItem d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGreyColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(d.icon, size: 18, color: blackColor60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.label,
                    style: TextStyle(
                        fontSize: 11,
                        color: blackColor60,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(d.value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: format relative date/time display
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 7) return DateFormat('MMM dd, yyyy').format(dt);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // Helper: parse & format ISO date string
  String _formatDate(dynamic iso) {
    if (iso == null) return 'N/A';
    try {
      final d = DateTime.parse(iso.toString());
      return DateFormat('MMM dd, yyyy HH:mm').format(d);
    } catch (_) {
      return iso.toString();
    }
  }

  // Helper: capitalize words
  String _capitalize(dynamic v) {
    final s = v?.toString() ?? '';
    return s
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
} // <== ensure this closing brace exists for _NotificationsScreenState

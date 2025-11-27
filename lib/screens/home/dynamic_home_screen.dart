import 'package:axeguide/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../settings_screen.dart';
import '../walkthrough/walkthrough_screen.dart';
import '../location_selection_screen.dart';
import 'package:axeguide/services/hive_service.dart';
import 'package:axeguide/services/user_mode_notifier.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class DynamicHomeScreen extends StatefulWidget {
  final String? overrideLocation;
  const DynamicHomeScreen({super.key, this.overrideLocation});

  @override
  State<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends State<DynamicHomeScreen> {
  final SupabaseService _sb = SupabaseService();

  String? userLocation;
  bool loading = true;

  Map<String, dynamic>? layoutForLocation;
  final Map<String, List<Map<String, dynamic>>> listData = {};
  final Map<String, bool> listLoading = {};


  String normalizeLocation(String location) {
    final lower = location.toLowerCase();
    if (lower.contains('acadia')) return 'acadia';
    if (lower.contains('airport')) return 'halifax_airport';
    if (lower.contains('new minas') || lower.contains('newminas')) return 'new_minas';
    if (lower.contains('wolfville')) return 'wolfville';
    if (lower.contains('kentville')) return 'kentville';
    if (lower.contains('halifax')) return 'halifax';
    return lower.replaceAll(' ', '_');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    setState(() => loading = true);

    final rawLoc = widget.overrideLocation ?? UserBoxHelper.userLocation;
    // ...existing code...
    if (rawLoc == null || rawLoc.trim().isEmpty) {
      setState(() => loading = false);
      // ...existing code...
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LocationSelectionScreen(
                locations: LocationOption.mainLocations,
              ),
            ),
          );
        });
      }
      return;
    }

    userLocation = normalizeLocation(rawLoc);
    // ...existing code...

    // Walkthrough logic: show walkthrough only if not completed/skipped for this location and not opted out
    final walkthroughDone = UserBoxHelper.walkthroughCompletedLocations.contains(userLocation);
    final globallyDisabled = UserBoxHelper.walkthroughGloballyDisabled;
    final skippedPersonalization = UserBoxHelper.skippedPersonalization;
    final hasSeenWelcome = UserBoxHelper.hasSeenWelcome;
    // ...existing code...
    if (!globallyDisabled && !walkthroughDone && !skippedPersonalization && !hasSeenWelcome) {
      // ...existing code...
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WalkthroughScreen(),
            ),
          );
        });
      }
      return;
    }

    layoutForLocation = await _loadLayout(userLocation!);
    // ...existing code...

    final sections =
        (layoutForLocation?['sections'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    for (final section in sections) {
      if (section['source'] is String) {
        // ...existing code...
        await _loadSectionList(section);
      }
    }
    setState(() => loading = false);
  }

  Future<Map<String, dynamic>?> _loadLayout(String normalized) async {
    try {
      final raw = await rootBundle.loadString('assets/home/home_layout.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final layout = decoded[normalized];
        if (layout is Map<String, dynamic>) {
          return layout;
        }
      }
      return null;
    } catch (e) {
      // ...existing code...
      return null;
    }
  }

  Future<void> _loadSectionList(Map<String, dynamic> section) async {
    final sectionTitle = (section['title'] ?? 'section').toString();
    final source = section['source'] as String;

    // ...existing code...
    
    listLoading[sectionTitle] = true;
    if (mounted) setState(() {});

    try {
      if (source == 'supabase.locations') {
        final filter = section['filter'] as Map<String, dynamic>?;
        
        List<Map<String, dynamic>> results;
        
        if (filter != null) {
          // Extract filter parameters
          final areaTag = filter['area_tag'] as String?;
          final categoryNames = filter['category_name'];
          final parentId = filter['parent_id'];
          final categoryId = filter['category_id'] as int?;

          // Handle parent_id null check
          final parentIdValue = filter.containsKey('parent_id') ? parentId as int? : null;

          // Convert category names to list
          final categoryList = categoryNames != null
              ? (categoryNames is List 
                  ? categoryNames.cast<String>() 
                  : [categoryNames.toString()])
              : null;

          // Use optimized service method with all filters
          results = await _sb.fetchLocationsByFilters(
            areaTag: areaTag,
            categoryNames: categoryList,
            parentId: parentIdValue,
            categoryId: categoryId,
          );
        } else {
          // No filter, use area tags based on current location
          results = await _sb.fetchLocationsByTags([userLocation!]);
        }
        
        // Sort locations alphabetically by name
        results.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        listData[sectionTitle] = results;
      }
      if (source == 'supabase.instagram_accounts') {
        final insta = await _sb.fetchInstagramAccounts();
        // Sort Instagram accounts alphabetically by account_name
        insta.sort((a, b) => (a['account_name'] ?? '').toString().compareTo((b['account_name'] ?? '').toString()));
        listData[sectionTitle] = insta;
      }
    } catch (e, stack) {
      // ...existing code...
      debugPrint("[Home] Stack trace: $stack");
      listData[sectionTitle] = [];
    } finally {
      listLoading[sectionTitle] = false;
      if (mounted) setState(() {});
    }
  }

  String _getLocationGreeting() {
    final loc = userLocation ?? '';
    switch (loc) {
      case 'acadia':
        return 'Acadia University';
      case 'halifax_airport':
        return 'Halifax Stanfield International Airport';
      case 'new_minas':
        return 'New Minas';
      case 'kentville':
        return 'Kentville';
      case 'wolfville':
        return 'Wolfville';
      case 'halifax':
        return 'Halifax';
      default:
        return loc.isEmpty ? 'Home' : loc;
    }
  }

  void _showLocationDetails(Map<String, dynamic> loc) {
    final name = loc['name'] ?? 'Unknown';
    final description = loc['description'] ?? '';
    final town = loc['town'] ?? '';
    final hours = loc['hours'] ?? '';
    final address = loc['address'] ?? '';
    final phone = loc['phone'] ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Title
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Info rows
                    if (town.isNotEmpty)
                      _detailRow(Icons.location_city, 'Town', town),
                    if (hours.isNotEmpty)
                      _detailRow(Icons.access_time, 'Hours', hours),
                    if (address.isNotEmpty)
                      _detailRow(Icons.location_on, 'Address', address),
                    if (phone.isNotEmpty)
                      _detailRow(Icons.phone, 'Phone', phone),
                    
                    const SizedBox(height: 24),
                    
                    // Open Map button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openMap(loc);
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Open in Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF013A6E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF013A6E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap(Map<String, dynamic> loc) async {
    final lat = loc['latitude'];
    final lng = loc['longitude'];
    final mapLink = loc['map_link'];
    Uri? uri;

    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else if (mapLink != null && mapLink.toString().isNotEmpty) {
      uri = Uri.tryParse(mapLink.toString());
    }

    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid map info available.")),
      );
      return;
    }

    try {
      if (kIsWeb) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Could not open map.")));
  }

  void _showExploreSheet() {
    const options = [
      "Acadia University",
      "Halifax Stanfield International Airport",
      "New Minas",
      "Kentville",
      "Wolfville",
      "Halifax",
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Where are we exploring today?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final loc in options)
              Card(
                child: ListTile(
                  title: Text(loc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showExploreChoice(loc);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showExploreChoice(String loc) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text("Browse here (don't change my Home)"),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DynamicHomeScreen(
                        overrideLocation: normalizeLocation(loc),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text("Set as my Home location"),
                onTap: () async {
                  final norm = normalizeLocation(loc);
                  debugPrint('[DynamicHomeScreen] Setting userLocation to: $norm');
                  await UserBoxHelper.setUserLocation(norm);
                  await HiveService.clearCacheForLocation(norm);
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  setState(() {
                    userLocation = norm;
                  });
                  await _initialize();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: userModeNotifier,
      builder: (context, userMode, _) {
        final sections = <Map<String, dynamic>>[];

        final isNewcomer = userMode == "newcomer";

        // Add newcomer sections at the top for this location
        if (isNewcomer && layoutForLocation?['newcomer_sections'] != null) {
          sections.addAll(
            (layoutForLocation!['newcomer_sections'] as List)
                .cast<Map<String, dynamic>>()
          );
        }

        // Add normal sections
        sections.addAll(
          (layoutForLocation?['sections'] as List?)?.cast<Map<String, dynamic>>() ?? []
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            title: const Text('The AxeGuide'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showExploreSheet,
            label: const Text('Explore'),
            icon: const Icon(Icons.explore_outlined),
            backgroundColor: const Color(0xFF013A6E),
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF013A6E)),
                  )
                : (layoutForLocation == null)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No layout found for '$userLocation'.\nCheck home_layout.json.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 24),
                        for (final section in sections) ...[
                          _buildSection(section),
                          const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF013A6E), const Color(0xFF025A9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013A6E).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.place_outlined,
              size: 28,
              color: Color(0xFFB6FF3C), // lime green accent
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              "Welcome to ${_getLocationGreeting()}!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final title = (section['title'] ?? '').toString();
    final source = (section['source'] ?? '').toString();
    final items = section['items'];

    // If section has items array, it's a links section
    if (items is List && items.isNotEmpty) {
      return _buildLinksSection(title, section);
    }
    
    // If section has a source (data from supabase), it's a list section
    if (source.isNotEmpty) {
      return _buildListSection(title, section);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLinksSection(String title, Map<String, dynamic> section) {
    final links =
        (section['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return _sectionCard(
      title: title,
      child: Column(
        children: links.map((l) {
          final label = (l['label'] ?? '').toString();
          final url = (l['url'] ?? '').toString();
          return ListTile(
            leading: const Icon(Icons.link, color: Color(0xFF013A6E)),
            title: Text(label),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListSection(String title, Map<String, dynamic> section) {
    final isLoading = listLoading[title] ?? false;
    final items = listData[title] ?? [];

    if (isLoading) {
      return _sectionCard(
        title: title,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: Color(0xFF013A6E)),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return _sectionCard(
        title: title,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Nothing here yet.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final source = section['source']?.toString() ?? '';

    // Locations list UI
    if (source == 'supabase.locations') {
      // Show More logic for Acadia locations only
      int initialLimit = 4;
      final ValueNotifier<bool> showAllNotifier = ValueNotifier(false);
      bool isAcadiaSection = (userLocation == 'acadia' && title.toLowerCase().contains('campus'));
      Widget buildLocations(List locationsToShow) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth <= 600;
            final crossAxisCount = isMobile ? 1 : (screenWidth > 1200 ? 4 : 3);
            final spacing = 12.0;
            final cardWidth = isMobile
              ? constraints.maxWidth
              : (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
            const cardHeight = 205.0;
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: locationsToShow.map<Widget>((loc) {
                    final name = loc['name'] ?? 'Unknown';
                    final description = loc['description'] ?? '';
                    final town = loc['town'] ?? '';
                    final hours = loc['hours'] ?? '';
                    return Container(
                      width: cardWidth,
                      height: cardHeight, // Restore fixed height to clip overflow
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showLocationDetails(loc),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF013A6E).withValues(alpha: 0.15),
                                            const Color(0xFF013A6E).withValues(alpha: 0.08),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.place_rounded,
                                        color: Color(0xFF013A6E),
                                        size: 20,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF013A6E).withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        color: Color(0xFF013A6E),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1A202C),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const Spacer(),
                                if (town.isNotEmpty || hours.isNotEmpty)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        if (town.isNotEmpty)
                                          Container(
                                            constraints: BoxConstraints(
                                              maxWidth: cardWidth * 0.5,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF013A6E).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.location_city_rounded,
                                                  size: 10,
                                                  color: const Color(0xFF013A6E).withValues(alpha: 0.8),
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    town,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF013A6E).withValues(alpha: 0.9),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (town.isNotEmpty && hours.isNotEmpty)
                                          const SizedBox(width: 6),
                                        if (hours.isNotEmpty)
                                          Container(
                                            constraints: BoxConstraints(
                                              maxWidth: cardWidth * 0.6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 10,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: LayoutBuilder(
                                                    builder: (context, constraints) {
                                                      final style = TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.green.shade800,
                                                      );
                                                      final check2Lines = TextPainter(
                                                        text: TextSpan(text: hours, style: style),
                                                        maxLines: 2,
                                                        textDirection: TextDirection.ltr,
                                                      )..layout(maxWidth: constraints.maxWidth);
                                                      if (!check2Lines.didExceedMaxLines) {
                                                        return Text(hours, style: style, maxLines: 2);
                                                      }
                                                      final ellipsisText = '...';
                                                      var endIndex = hours.length - 1;
                                                      while (endIndex > 10) {
                                                        final testText = hours.substring(0, endIndex).trimRight() + ellipsisText;
                                                        final testPainter = TextPainter(
                                                          text: TextSpan(text: testText, style: style),
                                                          maxLines: 2,
                                                          textDirection: TextDirection.ltr,
                                                        )..layout(maxWidth: constraints.maxWidth);
                                                        if (!testPainter.didExceedMaxLines) break;
                                                        endIndex -= 3;
                                                      }
                                                      while (endIndex > 0) {
                                                        final testText = hours.substring(0, endIndex).trimRight() + ellipsisText;
                                                        final testPainter = TextPainter(
                                                          text: TextSpan(text: testText, style: style),
                                                          maxLines: 2,
                                                          textDirection: TextDirection.ltr,
                                                        )..layout(maxWidth: constraints.maxWidth);
                                                        if (!testPainter.didExceedMaxLines) {
                                                          final finalIndex = (endIndex - 3).clamp(0, endIndex);
                                                          final finalText = hours.substring(0, finalIndex).trimRight() + ellipsisText;
                                                          return Text(finalText, style: style, maxLines: 2);
                                                        }
                                                        endIndex--;
                                                      }
                                                      return Text(ellipsisText, style: style);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      }
      if (isAcadiaSection && items.length > initialLimit) {
        return _sectionCard(
          title: title,
          child: ValueListenableBuilder<bool>(
            valueListenable: showAllNotifier,
            builder: (context, showAll, _) {
              final locationsToShow = showAll ? items : items.take(initialLimit).toList();
              return Column(
                children: [
                  buildLocations(locationsToShow),
                  if (!showAll)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF013A6E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => showAllNotifier.value = true,
                        child: const Text('Show More'),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      } else {
        return _sectionCard(
          title: title,
          child: buildLocations(items),
        );
      }
    }

    if (source == 'supabase.instagram_accounts') {
      int initialLimit = 4;
      final ValueNotifier<bool> showAllNotifier = ValueNotifier(false);
      Widget buildAccounts(List accountsToShow) {
        return Column(
          children: accountsToShow.map((acc) {
            return ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF013A6E),
              ),
              title: Text(acc['account_name'] ?? 'Instagram Account'),
              subtitle: Text(
                acc['handles'] != null ? "@${acc['handles']}" : '',
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () async {
                final handle = acc['handles'];
                if (handle != null && handle.toString().isNotEmpty) {
                  final url =
                      "https://instagram.com/${handle.toString().replaceAll('@', '')}";
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
            );
          }).toList(),
        );
      }
      if (items.length > initialLimit) {
        return _sectionCard(
          title: title,
          child: ValueListenableBuilder<bool>(
            valueListenable: showAllNotifier,
            builder: (context, showAll, _) {
              final accountsToShow = showAll ? items : items.take(initialLimit).toList();
              return Column(
                children: [
                  buildAccounts(accountsToShow),
                  if (!showAll)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF013A6E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => showAllNotifier.value = true,
                        child: const Text('Show More'),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      } else {
        return _sectionCard(
          title: title,
          child: buildAccounts(items),
        );
      }
    }

    return _sectionCard(
      title: title,
      child: const SizedBox.shrink(),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013A6E).withValues(alpha: .07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF013A6E),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

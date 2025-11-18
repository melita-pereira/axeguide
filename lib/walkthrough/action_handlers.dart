import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:axeguide/screens/home_screen.dart';

typedef WTActionHandler = Future<void> Function(
  BuildContext context,
  String action,
  Map<String, dynamic>? params,
);

class WalkthroughActions {
  static Future<void> handle(
    BuildContext context,
    String action,
    Map<String, dynamic>? params,
  ) async {

    switch (action) {

      case "importHiveCheckpoint":
      return _importHiveCheckpoint(context);

      case "setNavigationPreference.in_depth":
        await UserBoxHelper.setNavPreference("in-depth");
        return;

      case "setNavigationPreference.basic":
        await UserBoxHelper.setNavPreference("basic");
        return;

      case "showImmigrationBaggageHelp":
        return _showInfoDialog(context, "Immigration & Baggage Help",
            "Follow signs to Canada Border Services for landing documents. Baggage claim is straight after immigration.");
      
      case "showShuttleGuidance":
        return _showInfoDialog(context, "University Shuttle",
            "Acadia's airport shuttle picks up outside the main exit. Have your confirmation email ready.");

      case "showAirportHelp":
        return _showInfoDialog(context, "Airport Help",
            "Go to the International Student Help Desk near Arrivals.");

      case "showTaxiGuidance":
        return _showInfoDialog(context, "Taxi",
            "Official taxis line up outside Arrivals. Expect \$70-90 to Wolfville and \$25-35 to downtown Halifax.");

      case "showBusGuidance":
        return _showInfoDialog(context, "Public Bus",
            "MetroTransit 320 runs from the Airport → Downtown Halifax. \$5 fare.");

      case "showSIMKioskInfo":
        return _showInfoDialog(context, "SIM Card",
            "The airport’s Chatr / Rogers kiosk sells prepaid SIMs without ID.");

      case "displayAirportHelpInfo":
        return _showInfoDialog(context, "Airport Assistance",
            "Staff can help with connecting flights, baggage issues, or directions.");

      case "navigateToAirportHomeScreen":
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showShuttlePointers":
        return _showInfoDialog(context, "Shuttle Arrival",
            "If you arrived via shuttle, pickup is outside Wheelock Dining Hall.");

      case "enterOffCampusAddress":
        return _showInfoDialog(context, "Off-Campus Housing",
            "Search your new address on the map to get directions from campus.");

      case "showCampusDirections":
        return _showInfoDialog(context, "Campus Directions",
            "Choose your residence to get step-by-step walking directions.");

      case "navigateToAcadiaHomeScreen":
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showSIMDirections":
        return _showInfoDialog(context, "SIM Locations",
            "Wong Centre has student SIMs. New Minas has full mobile stores.");

      case "showWolfvilleEssentials":
        return _showInfoDialog(context, "Wolfville Essentials",
            "Nearby: Independent Grocers, Shoppers, MacQuarries Pharmasave, Valley Transit stops.");

      case "navigateToWolfvilleHomeScreen":
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showNewMinasEssentials":
        return _showInfoDialog(context, "New Minas Essentials",
            "Walmart, Superstore, NSLC, and many retail stores here.");

      case "navigateToNewMinasHomeScreen":
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showKentvilleEssentials":
        return _showInfoDialog(context, "Kentville Essentials",
            "Government services and medical centres are here.");

      case "navigateToKentvilleHomeScreen":
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showHalifaxTransitGuide":
        return _showInfoDialog(context, "Halifax Transit",
            "Use the Transit app. Buses are \$2.75 (exact change).");

      case "showHalifaxTaxiGuide":
        return _showInfoDialog(context, "Taxi",
            "Uber, Lyft, and local taxis operate widely.");

      case "showHalifaxCarRentalGuide":
        return _showInfoDialog(context, "Car Rental",
            "Enterprise and Budget are available downtown.");

      case "showHalifaxSIMLocations":
        return _showInfoDialog(context, "SIM Card",
            "Walmart, Atlantic Superstore, and MobileKlinik sell SIMs.");

      case "showHalifaxGroceriesPharmacy":
        return _showInfoDialog(context, "Groceries & Pharmacy",
            "Sobeys, Superstore, Shoppers Drug Mart available citywide.");

      case "showHalifaxBankingOptions":
        return _showInfoDialog(context, "Banking",
            "BMO, RBC, Scotiabank, CIBC — bring passport + study permit.");

      case "showHalifaxAttractions":
        return _showInfoDialog(context, "Halifax Highlights",
            "Harbourfront, Citadel Hill, Seaport Market, Public Gardens.");

      case "navigateToHalifaxHomeScreen":
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      default:
        debugPrint("[Walkthrough] Unknown action: $action");
    }
  }

  static Future<void> _showInfoDialog(
      BuildContext context, String title, String content) async {
    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("OK")),
        ],
      ),
    );
  }

  static Future<void> _importHiveCheckpoint(BuildContext context) async {
    final savedStep = UserBoxHelper.walkthroughCheckpoint;
    final savedLocation = UserBoxHelper.userLocation;
    final navPref = UserBoxHelper.navPreference;

    debugPrint("Restoring checkpoint: $savedStep");
    debugPrint("Restoring location: $savedLocation");
    debugPrint("Restoring navigation preference: $navPref");

    
    // Simulate some delay
    await Future.delayed(const Duration(seconds: 1));
    debugPrint("Hive checkpoint imported.");
  }
}
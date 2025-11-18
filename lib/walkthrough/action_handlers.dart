import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:axeguide/screens/home_screen.dart';
import 'package:axeguide/screens/walkthrough/guidance_screen.dart';

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
        return _showGuidance(
          context,
          title: "Immigration & Baggage",
          content: "Here's what to expect when you arrive at Halifax Airport.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Follow signs to Canada Border Services Agency (CBSA)",
                  "Have your passport, study permit, and landing documents ready",
                  "Answer the officer's questions about your stay",
                  "Proceed to baggage claim after clearing immigration",
                  "Collect all your luggage from the carousel",
                  "Exit through customs (usually just walk through if nothing to declare)"
                ]
              : [
                  "Follow signs to Canada Border Services",
                  "Have passport and study permit ready",
                  "Collect baggage and exit through customs"
                ],
        );
      
      case "showShuttleGuidance":
        return _showGuidance(
          context,
          title: "University Shuttle",
          content: "Acadia's airport shuttle service provides convenient transportation from Halifax Airport to campus.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Exit through the main doors at Halifax Airport Arrivals",
                  "Look for the Acadia University shuttle outside the main exit",
                  "Have your confirmation email ready to show the driver",
                  "Load your luggage in the designated area",
                  "The shuttle will drop you at your assigned residence or Student Services"
                ]
              : [
                  "Find the Acadia shuttle outside the main exit",
                  "Show your confirmation email",
                  "Board and relax - you'll be dropped at campus"
                ],
        );

      case "showFriendFamilyGuidance":
        return _showGuidance(
          context,
          title: "Friend/Family Pickup",
          content: "Getting picked up by someone you know? Here's how the process works at Halifax Airport.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Collect all your luggage from baggage claim",
                  "Exit through the Arrivals doors",
                  "Have your contact call or text when they arrive at the pickup area",
                  "Look for the pickup lane - it's clearly marked outside Arrivals",
                  "Load your luggage and you're good to go!"
                ]
              : [
                  "Get your luggage from baggage claim",
                  "Exit to Arrivals pickup area",
                  "Meet your contact at the pickup lane"
                ],
        );

      case "showAirportHelp":
        return _showGuidance(
          context,
          title: "Airport Help Desk",
          content: "Need assistance? The International Student Help Desk can guide you.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Look for the International Student Help Desk near Arrivals",
                  "Staff can help with directions and immediate questions",
                  "They can assist with transport options",
                  "They may have campus information for you"
                ]
              : [
                  "Find the International Student Help Desk near Arrivals",
                  "Staff can help with directions and questions"
                ],
        );

      case "showTaxiGuidance":
        return _showGuidance(
          context,
          title: "Taking a Taxi",
          content: "Taxis are a reliable option for getting to your destination from Halifax Airport.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Exit through the main doors at Arrivals",
                  "Look for the official taxi stand outside",
                  "Official taxis are metered and regulated",
                  "Expect to pay \$70-90 to Wolfville/Acadia",
                  "To downtown Halifax, expect \$25-35",
                  "You can pay by cash or card"
                ]
              : [
                  "Find the official taxi stand outside Arrivals",
                  "\$70-90 to Wolfville, \$25-35 to Halifax downtown",
                  "Cash or card accepted"
                ],
        );

      case "showBusGuidance":
        return _showGuidance(
          context,
          title: "Public Bus (MetroTransit)",
          content: "The affordable way to get from Halifax Airport to downtown Halifax.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Exit the airport and look for the bus stop signs",
                  "Take MetroTransit Route 320 (Airport Express)",
                  "Buses run regularly throughout the day",
                  "Have exact change ready (\$5 fare)",
                  "The bus goes to downtown Halifax",
                  "Trip takes about 30-40 minutes"
                ]
              : [
                  "Find the MetroTransit 320 bus stop outside",
                  "Fare is \$5 (exact change)",
                  "Goes to downtown Halifax in 30-40 min"
                ],
        );

      case "showSIMKioskInfo":
        return _showGuidance(
          context,
          title: "Getting a SIM Card",
          content: "Need a Canadian phone number? The airport has options for you.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Look for the Chatr or Rogers kiosk in the airport",
                  "Prepaid SIM cards are available without ID",
                  "Plans start around \$15-25 per month",
                  "Ask about student discounts if available",
                  "Staff will help you activate it on the spot"
                ]
              : [
                  "Find Chatr/Rogers kiosk in airport",
                  "Prepaid SIMs available, no ID needed",
                  "Plans from \$15-25/month"
                ],
        );

      case "displayAirportHelpInfo":
        return _showGuidance(
          context,
          title: "Airport Assistance",
          content: "Airport staff are here to help you navigate your arrival.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Look for airport staff in red vests or uniforms",
                  "They can help with connecting flights",
                  "Ask about baggage issues or lost items",
                  "They can give directions within the airport"
                ]
              : [
                  "Airport staff can help with flights, baggage, and directions",
                  "Look for staff in red vests"
                ],
        );

      case "navigateToAirportHomeScreen":
        // Ensure user has a mode set
        if (UserBoxHelper.userMode == null) {
          await UserBoxHelper.setUserMode('Student');
        }
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showShuttlePointers":
        return _showGuidance(
          context,
          title: "Arriving by Shuttle",
          content: "Arriving at Acadia via shuttle? Here's what to expect.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "The shuttle will drop you outside Wheelock Dining Hall",
                  "Look for campus signs to orient yourself",
                  "Head to Student Services if you need help",
                  "Your residence assignment info will guide you from there"
                ]
              : [
                  "Shuttle drops at Wheelock Dining Hall",
                  "Head to Student Services for help"
                ],
        );

      case "showFriendFamilyPointers":
        return _showGuidance(
          context,
          title: "Friend/Family Drop-off",
          content: "Getting dropped off at Acadia by someone you know.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Visitor parking is near the main campus entrance",
                  "Have them drop you at Student Services first",
                  "Check in and get your residence keys",
                  "Staff will direct you to your residence from there"
                ]
              : [
                  "Drop-off at Student Services",
                  "Check in and get residence info"
                ],
        );

      case "showBusPointers":
        return _showGuidance(
          context,
          title: "Arriving by Bus",
          content: "Taking Valley Transit to campus? Here's your arrival plan.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Valley Transit stops at the main campus entrance",
                  "Look for campus directory signs",
                  "Walk to Student Services to check in",
                  "It's a short walk from the bus stop"
                ]
              : [
                  "Bus stops at main entrance",
                  "Walk to Student Services"
                ],
        );

      case "showTaxiPointers":
        return _showGuidance(
          context,
          title: "Arriving by Taxi",
          content: "Taking a taxi to Acadia? Here's where to go.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Ask the driver to drop you at Student Services",
                  "Or go directly to your residence if you know the location",
                  "Have your residence name ready for the driver",
                  "Payment by cash or card"
                ]
              : [
                  "Drop-off at Student Services or your residence",
                  "Cash or card accepted"
                ],
        );

      case "showCampusResDirections":
        return _showGuidance(
          context,
          title: "Campus Residence",
          content: "Finding your way to your campus residence.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Check your residence assignment email",
                  "Common residences: Cutten, Chipman, Crowell Tower, Dennis House",
                  "Look for campus directory signs",
                  "Ask Student Services staff if you need help",
                  "Most residences are within a 5-10 minute walk from Student Services"
                ]
              : [
                  "Check your residence assignment",
                  "Look for directory signs or ask Student Services",
                  "Most residences are 5-10 min walk from Student Services"
                ],
        );

      case "enterOffCampusAddress":
        return _showGuidance(
          context,
          title: "Off-Campus Housing",
          content: "Living off-campus? Here's how to navigate to and from campus.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Most off-campus housing in Wolfville is walkable",
                  "Use Google Maps for specific directions to your address",
                  "Valley Transit has routes throughout Wolfville",
                  "Biking is popular - campus has bike racks",
                  "Winter can be snowy - plan for extra travel time"
                ]
              : [
                  "Most housing is walkable in Wolfville",
                  "Use Google Maps for directions",
                  "Valley Transit available"
                ],
        );

      case "showCampusDirections":
        return _showGuidance(
          context,
          title: "Getting Around Campus",
          content: "Acadia's campus is compact and easy to navigate.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Campus is fully walkable - most buildings within 10 minutes",
                  "Main landmarks: University Hall (center), KC Irving Centre (library)",
                  "Wheelock Dining Hall and Student Union Building are central meeting points",
                  "Campus maps are posted at major intersections",
                  "Download the Acadia app for an interactive campus map"
                ]
              : [
                  "Campus is fully walkable (10 min max)",
                  "Use posted maps or Acadia app",
                  "Main buildings: University Hall, Library, Student Union"
                ],
        );

      case "navigateToAcadiaHomeScreen":
        if (UserBoxHelper.userMode == null) {
          await UserBoxHelper.setUserMode('Student');
        }
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showSIMDirections":
        return _showGuidance(
          context,
          title: "Getting a SIM Card",
          content: "Need a Canadian phone number in the Valley?",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "On campus: Visit Wong Centre for student SIM options",
                  "In New Minas: Full mobile stores available (Rogers, Bell, Telus)",
                  "Bring passport and study permit",
                  "Plans range from \$15-50/month",
                  "Ask about student discounts"
                ]
              : [
                  "Wong Centre (on campus) or New Minas mobile stores",
                  "Bring passport and study permit"
                ],
        );

      case "showWolfvilleEssentials":
        return _showGuidance(
          context,
          title: "Wolfville Essentials",
          content: "Everything you need is within walking distance in Wolfville.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Groceries: Independent Grocers on Main Street",
                  "Pharmacy: Shoppers Drug Mart or MacQuarries Pharmasave",
                  "Transit: Valley Transit stops throughout town",
                  "Banking: RBC, Scotiabank on Main Street",
                  "Most shops are within 10-15 min walk from campus"
                ]
              : [
                  "Independent Grocers, Shoppers, MacQuarries Pharmasave",
                  "Valley Transit available",
                  "All walkable from campus"
                ],
        );

      case "navigateToWolfvilleHomeScreen":
        if (UserBoxHelper.userMode == null) {
          await UserBoxHelper.setUserMode('Student');
        }
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showNewMinasEssentials":
        return _showGuidance(
          context,
          title: "New Minas Essentials",
          content: "New Minas is the Valley's main shopping hub.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Major stores: Walmart, Atlantic Superstore",
                  "Liquor: NSLC (government liquor store)",
                  "Many retail stores and restaurants",
                  "Take Valley Transit or taxi from Wolfville",
                  "About 10 minutes from Acadia"
                ]
              : [
                  "Walmart, Superstore, NSLC",
                  "Many retail options",
                  "10 min from Acadia by bus/taxi"
                ],
        );

      case "navigateToAcadiaAttractionsHomeScreen":
        if (UserBoxHelper.userMode == null) {
          await UserBoxHelper.setUserMode('Student');
        }
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showKentvilleEssentials":
        return _showGuidance(
          context,
          title: "Kentville Essentials",
          content: "Kentville is the Valley's administrative center.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Government services: Service Nova Scotia office",
                  "Medical: Valley Regional Hospital",
                  "Walk-in clinics available",
                  "About 15 minutes from Acadia",
                  "Take Valley Transit or taxi"
                ]
              : [
                  "Government offices and medical centers",
                  "Valley Regional Hospital",
                  "15 min from Acadia"
                ],
        );

      case "navigateToKentvilleHomeScreen":
        if (UserBoxHelper.userMode == null) {
          await UserBoxHelper.setUserMode('Student');
        }
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showHalifaxTransitGuide":
        return _showGuidance(
          context,
          title: "Halifax Transit",
          content: "Getting around Halifax using public transit.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Download the Halifax Transit app for schedules",
                  "Buses run frequently on main routes",
                  "Fare is \$2.75 (exact change required)",
                  "You can buy tickets at convenience stores",
                  "Monthly passes available for regular users",
                  "Service is reduced on weekends and evenings"
                ]
              : [
                  "Use Halifax Transit app for schedules",
                  "Fare: \$2.75 (exact change)",
                  "Monthly passes available"
                ],
        );

      case "showHalifaxTaxiGuide":
        return _showGuidance(
          context,
          title: "Taxis & Ride-sharing",
          content: "Getting around Halifax by taxi or ride-share.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Uber and Lyft operate in Halifax",
                  "Download apps and set up payment in advance",
                  "Local taxi companies also available",
                  "Taxis can be hailed on the street downtown",
                  "Most rides within Halifax cost \$10-25",
                  "Late night (after midnight) may have higher rates"
                ]
              : [
                  "Uber, Lyft, and local taxis available",
                  "Most rides: \$10-25 within Halifax",
                  "Download apps for ride-sharing"
                ],
        );

      case "showHalifaxCarRentalGuide":
        return _showGuidance(
          context,
          title: "Car Rental",
          content: "Renting a car in Halifax for exploring the region.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Enterprise and Budget have downtown locations",
                  "You need: valid driver's license and credit card",
                  "International students: check if you need International Driving Permit",
                  "Book online for better rates",
                  "Gas is sold by the liter (not gallon)",
                  "Insurance is required - check what your card covers"
                ]
              : [
                  "Enterprise and Budget available downtown",
                  "Need: license and credit card",
                  "Book online for better rates"
                ],
        );

      case "showHalifaxSIMLocations":
        return _showGuidance(
          context,
          title: "Getting a SIM Card",
          content: "Need a phone number? Halifax has many options.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Walmart and Atlantic Superstore sell prepaid SIMs",
                  "Mobile stores: Rogers, Bell, Telus, Fido, Koodo",
                  "MobileKlinik for repairs and SIM cards",
                  "Bring passport and study permit",
                  "Plans start around \$15-25/month for prepaid",
                  "Ask about student discounts"
                ]
              : [
                  "Walmart, Superstore, or mobile stores",
                  "Bring passport and study permit",
                  "Plans from \$15-25/month"
                ],
        );

      case "showHalifaxGroceriesPharmacy":
        return _showGuidance(
          context,
          title: "Groceries & Pharmacy",
          content: "Finding essentials in Halifax.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Major chains: Sobeys, Atlantic Superstore, Pete's Frootique",
                  "Pharmacies: Shoppers Drug Mart, Lawtons (open late)",
                  "Downtown has smaller shops and specialty stores",
                  "Many stores offer delivery or pickup",
                  "Farmer's markets on weekends for fresh produce",
                  "Most stores open 8am-10pm daily"
                ]
              : [
                  "Sobeys, Superstore, Pete's Frootique",
                  "Shoppers Drug Mart, Lawtons for pharmacy",
                  "Most open 8am-10pm"
                ],
        );

      case "showHalifaxBankingOptions":
        return _showGuidance(
          context,
          title: "Banking Services",
          content: "Setting up a bank account in Halifax.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Major banks: BMO, RBC, Scotiabank, TD, CIBC",
                  "Bring: passport, study permit, proof of enrollment",
                  "Many banks offer student accounts with no fees",
                  "You can book an appointment online",
                  "Ask about international student packages",
                  "Interac Debit is the most common payment method"
                ]
              : [
                  "BMO, RBC, Scotiabank, TD, CIBC available",
                  "Bring passport + study permit + enrollment proof",
                  "Student accounts often have no fees"
                ],
        );

      case "showHalifaxAttractions":
        return _showGuidance(
          context,
          title: "Halifax Highlights",
          content: "Must-see attractions and experiences in Halifax.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Halifax Harbourfront - waterfront boardwalk (free)",
                  "Citadel Hill - historic fort with city views (admission fee)",
                  "Halifax Seaport Farmers' Market - local food and crafts (weekends)",
                  "Public Gardens - Victorian gardens (free, seasonal)",
                  "Maritime Museum of the Atlantic - Titanic exhibits",
                  "Pier 21 - Canadian immigration museum",
                  "Downtown has great restaurants and nightlife"
                ]
              : [
                  "Harbourfront boardwalk (free)",
                  "Citadel Hill for views",
                  "Seaport Market, Public Gardens",
                  "Maritime Museum, Pier 21"
                ],
        );

      case "navigateToHalifaxHomeScreen":
        if (UserBoxHelper.userMode == null) {
          await UserBoxHelper.setUserMode('Student');
        }
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        return;

      case "showNavigationFromTo":
        final currentLocation = UserBoxHelper.currentCampusLocation;
        final destination = UserBoxHelper.destinationLocation;
        
        return _showGuidance(
          context,
          title: "Navigation: $currentLocation → $destination",
          content: "Here's how to get from $currentLocation to $destination.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Starting point: $currentLocation",
                  "Destination: $destination",
                  "Look for campus directory signs along the way",
                  "Walking time: approximately 5-10 minutes",
                  "If you need help, ask any staff member or student",
                  "The route will be shown on the map in the home screen"
                ]
              : [
                  "From: $currentLocation",
                  "To: $destination",
                  "Follow campus signs or check map"
                ],
        );

      default:
        debugPrint("[Walkthrough] Unknown action: $action");
    }
  }

  static Future<void> _showGuidance(
    BuildContext context, {
    required String title,
    required String content,
    List<String>? steps,
    List<String>? images,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuidanceScreen(
          title: title,
          content: content,
          steps: steps,
          images: images,
          onComplete: () => Navigator.pop(context),
        ),
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
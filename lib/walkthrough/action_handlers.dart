import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:axeguide/screens/home/dynamic_home_screen.dart';
import 'package:axeguide/screens/walkthrough/guidance_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  "Follow signs to Canada Border Services Agency (CBSA) Port of Entry",
                  "Have your passport, study permit approval letter, letter of acceptance, and other landing documents ready",
                  "Answer the officer's questions about your stay",
                  "Receive your visa/study permit stamp or document from the immigration officer",
                  "Proceed to baggage claim after clearing immigration",
                  "Collect all your luggage from the carousel",
                  "Exit"
                ]
              : [
                  "Follow signs to Canada Border Services",
                  "Have passport and study permit ready",
                  "Collect baggage and exit"
                ],
        );
      
      case "showShuttleGuidance":
        return _showGuidance(
          context,
          title: "University Shuttle",
          content: "Acadia's airport shuttle service provides convenient transportation from Halifax Airport to campus.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Find the International Centre's booth - typically set up after the baggage claim area",
                  "Check in with your name and flight details",
                  "Wait in the designated area for the shuttle bus",
                  "Board the shuttle when it arrives - you may need to walk a short distance. Follow your airport pickup team from the International Centre",
                  "Load your luggage and get comfortable - typically would go underneath the bus",
                  "Enjoy the 1 hourride to campus - the shuttle will drop you off at the Student Union Building"
                ]
              : [
                  "Find the International Centre's booth after baggage claim",
                  "Show your confirmation email",
                  "Wait and board the shuttle to campus"
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
          content: "Need assistance? The Help Desk can guide you.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Look for the Help Desk near Arrivals - typically on your right as you exit from the baggage claim area",
                  "Staff can help with directions and immediate questions",
                  "They can assist with transport options",
                  "They may have campus information for you"
                ]
              : [
                  "Find the Help Desk near Arrivals",
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
                  "Check in with the Ground Transportation desk inside the terminal for taxi information - typically located near the main exit on your right after you exit from baggage claim",
                  "Give your details to the dispatcher",
                  "Wait for your taxi to arrive",
                  "Expect to pay \$70-90 to Wolfville/Acadia",
                  "To downtown Halifax, expect \$25-35",
                  "You can pay by cash or card"
                ]
              : [
                  "Find the official Ground Transportation desk near Arrivals",
                  "\$70-90 to Wolfville, \$25-35 to Halifax downtown",
                  "Cash or card accepted"
                ],
        );

      case "showBusGuidance":
        return _showGuidance(
          context,
          title: "Public Bus",
          content: "The affordable way to get from Halifax Airport to your destination.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Check in with the Ground Transportation desk inside the terminal for bus information - typically located near the main exit on your right after you exit from baggage claim",
                  "If you don't have a ticket, you can purchase one there for Regional Express 320 which will take you to Downtown Halifax",
                  "Maritime Bus Line also operates from the airport to various locations - check their schedule in advance",
                  "Maritime Bus only has 1 departure per day, so plan accordingly if you choose this option to get to Wolfville/Acadia",
                ]
              : [
                  "Check in with Bus Desk near Arrivals",
                  "Choose between Regional Express 320 or Maritime Bus",
                  "Pay the fare and board the bus when it arrives"
                ],
        );

      case "showSIMKioskInfo":
        return _showGuidance(
          context,
          title: "Getting a SIM Card",
          content: "Need a Canadian phone number? The airport has options for you.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Look for the Fido or Rogers kiosk in the airport",
                  "Plans start around \$15-25 per month",
                  "Ask about student discounts if available",
                  "Staff will help you activate it on the spot"
                ]
              : [
                  "Find Fido/Rogers kiosk in airport",
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
                  "Look for airport staff in uniforms",
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
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
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
                  "The shuttle will drop you outside Student Union Building",
                  "Look for campus signs to orient yourself",
                  "Head to the Safety and Security office if you need help",
                  "Your student orientation leaders will guide you from there"
                ]
              : [
                  "Shuttle drops at Student Union Building",
                  "Head to the Safety and Security office for help"
                ],
        );

      case "showFriendFamilyPointers":
        return _showGuidance(
          context,
          title: "Friend/Family Drop-off",
          content: "Getting dropped off at Acadia by someone you know.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Visitor parking is at several lots around campus - look for signs",
                  "Have them drop you at Student Union Building first",
                  "Check in with the Safety and Security office and get your keys",
                  "Staff will direct you to your residence from there"
                ]
              : [
                  "Drop-off at Student Union Building",
                  "Check in and get residence info"
                ],
        );

      case "showBusPointers":
        return _showGuidance(
          context,
          title: "Arriving by Bus",
          content: "Taking Maritime Bus to campus? Here's your arrival plan.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Maritime Bus stops at the Wheelock Dining Hall",
                  "Look for campus directory signs",
                  "Walk to the Safety and Security office inside the Student Union Building to check in",
                  "It's a short walk from the bus stop - downhill, at 30 Highland Ave"
                ]
              : [
                  "Bus stops at Wheelock Dining Hall",
                  "Walk to the Safety and Security office"
                ],
        );

      case "showTaxiPointers":
        return _showGuidance(
          context,
          title: "Arriving by Taxi",
          content: "Taking a taxi to Acadia? Here's where to go.",
          steps: UserBoxHelper.navPreference == "in-depth"
              ? [
                  "Ask the driver to drop you at the Student Union Building",
                  "Or go directly to your residence if you know the location and have the keys",
                  "Have your residence name ready for the driver",
                  "Payment by cash or card"
                ]
              : [
                  "Drop-off at Student Union Building or your residence",
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
                  "Residences: 55 University Ave, Chipman House, Crowell Tower, Dennis House, Roy Jodrey Hall, Christopher Hall, Eaton House, Chase Court, Whitman House",
                  "Look for campus directory signs",
                  "Ask Student Union Building staff or your orientation leaders if you need help",
                  "Most residences are within a 5-10 minute walk from Student Union Building"
                ]
              : [
                  "Check your residence assignment",
                  "Look for directory signs or ask Student Union Building staff",
                  "Most residences are 5-10 min walk from Student Union Building"
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
                  "Kings Transit has routes throughout Wolfville",
                  "Biking is popular - campus has bike racks",
                  "Winter can be snowy - plan for extra travel time"
                ]
              : [
                  "Most housing is walkable in Wolfville",
                  "Use Google Maps for directions",
                  "Kings Transit available"
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
                  "Main landmarks: University Hall (center), Beveridge Arts Centre (main classroom building)",
                  "Wheelock Dining Hall and Student Union Building are central meeting points",
                  "Campus directions are posted at major intersections",
                  "Check the Acadia website for a map"
                ]
              : [
                  "Campus is fully walkable (10 min max)",
                  "Use posted maps",
                  "Main buildings: University Hall, Library, Student Union"
                ],
        );

      case "navigateToAcadiaHomeScreen":
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
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
                  "Groceries: Independent Grocers on Main Street or Shoppers Drug Mart",
                  "Pharmacy: Shoppers Drug Mart or MacQuarries Pharmasave",
                  "Transit: Kings Transit stops throughout town",
                  "Banking: RBC, BMO on Main Street",
                  "Most shops are within 10-15 min walk from campus"
                ]
              : [
                  "Independent Grocers, Shoppers, MacQuarries Pharmasave",
                  "Kings Transit available",
                  "All walkable from campus"
                ],
        );

      case "navigateToWolfvilleHomeScreen":
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
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
                  "Major stores: Walmart, Atlantic Superstore, Dollarama, Winners",
                  "Shopping Centre: County Fair Mall",
                  "Many retail stores and restaurants",
                  "Take Kings Transit or taxi from Wolfville",
                  "About 10 minutes from Acadia"
                ]
              : [
                  "Walmart, Superstore, County Fair Mall",
                  "Many retail options",
                  "10 min from Acadia by bus/taxi"
                ],
        );

      case "navigateToNewMinasHomeScreen":
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
          (route) => false,
        );

        return;

      case "navigateToAcadiaAttractionsHomeScreen":
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
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
                  "About 15 minutes from Acadia",
                  "Take Kings Transit or taxi"
                ]
              : [
                  "Government offices and medical centers",
                  "Valley Regional Hospital",
                  "15 min from Acadia"
                ],
        );

      case "navigateToKentvilleHomeScreen":
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
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
                  "Use Transsee for schedules",
                  "Buses run frequently on main routes",
                  "Fare is \$2.75",
                ]
              : [
                  "Use Transsee for schedules",
                  "Fare: \$2.75"
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
        // Clear checkpoint - walkthrough completed
        await UserBoxHelper.clearWalkthroughCheckpoint();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
          (route) => false,
        );

        return;

      case "showNavigationFromTo":
        final currentLocation = UserBoxHelper.currentCampusLocation;
        final destination = UserBoxHelper.destinationLocation;
        List<String> steps;
        final lat = UserBoxHelper.destinationLatitude;
        final lng = UserBoxHelper.destinationLongitude;
        final mapsButton = (lat != null && lng != null)
            ? () async {
                final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            : null;
        if (UserBoxHelper.navPreference == "in-depth") {
          steps = [
            "Start at: $currentLocation",
            "Head towards: $destination",
            "Follow posted campus signs and directory maps",
            "Ask staff or students for help if needed",
            "Estimated walk time: 5-10 minutes",
            "Check the map on the home screen for your route"
          ];
        } else {
          steps = [
            "From: $currentLocation",
            "To: $destination",
            "Follow campus signs or use the map"
          ];
        }
        return _showGuidance(
          context,
          title: "Navigation: $currentLocation → $destination",
          content: "Here's how to get from $currentLocation to $destination.",
          steps: steps,
          images: null,
          // Pass a callback for opening maps if available
          onOpenMap: mapsButton,
        );

      default:
        // Unknown action
    }
  }

  static Future<void> _showGuidance(
    BuildContext context, {
    required String title,
    required String content,
    List<String>? steps,
    List<String>? images,
    VoidCallback? onOpenMap,
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
          onOpenMap: onOpenMap,
        ),
      ),
    );
  }

  static Future<void> _importHiveCheckpoint(BuildContext context) async {
    // The checkpoint restoration happens automatically when WalkthroughManager loads
    // This action just needs to navigate to the home screen since the user chose to continue
    
    // Clear the walkthrough checkpoint since they're continuing to home
    await UserBoxHelper.clearWalkthroughCheckpoint();
    
    if (!context.mounted) return;
    
    // Navigate to home screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
      (route) => false,
    );
  }
}
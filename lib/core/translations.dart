import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_controller.dart';
import 'package:intl/intl.dart';

class T {
  static const _map = <String, Map<String, String>>{
    'en': {
      // Nav
      'home': 'Home',
      'messages': 'Messages',
      'transactions': 'Transactions',
      'profile': 'Profile',

      // Settings
      'settings': 'Settings',
      'preferences': 'Preferences',
      'language': 'Language',
      'support': 'Support',
      'help_centre': 'Help Centre',
      'terms': 'Terms & Conditions',
      'about': 'About PasaBuy',
      'account': 'Account',
      'sign_out': 'Sign Out',
      'delete_account': 'Request account deletion',
      'change_password': 'Change password',
      'change_password_sub': 'Update your account password',

      // Common actions
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'saved': 'Saved',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'loading': 'Loading…',
      'submit': 'Submit',
      'close': 'Close',
      'delete': 'Delete',
      'edit': 'Edit',
      'view': 'View',
      'share': 'Share',
      'copy': 'Copy',
      'report': 'Report',
      'message': 'Message',
      'search': 'Search',

      // Dialogs
      'logout_title': 'Sign out?',
      'logout_body': "You'll need to sign in again to continue.",
      'logout_action': 'Sign out',
      'delete_post_title': 'Delete this post?',
      'delete_post_body':
          "This will cancel the pasabuy. It won't appear in the feed anymore.",
      'mark_done_title': 'Mark this pasabuy as done?',
      'mark_done_body':
          'Others will no longer be able to send new messages for this post. '
              'People already in a conversation can still chat.',
      'mark_done_action': 'Done deal',

      // Feed
      'search_pasabuy': 'Search pasabuy...',
      'post_pasabuy': 'Post pasabuy',
      'find_pasabuy': 'Find pasabuy',
      'my_deals': 'My Deals',
      'no_pasabuys': 'No pasabuys yet',
      'no_pasabuys_sub': 'Be the first to post a pasabuy offer or request.',
      'whats_your_pasabuy': "What's your pasabuy?",
      'offer': 'Offer',
      'request': 'Request',
      'photo': 'Photo',

      // Post card
      'pasabuy_offer': 'Pasabuy Offer',
      'buy_request': 'Buy Request',
      'pasa_buy_user': 'PasaBuy User', // NEW
      'you': 'You',
      'recently': 'Recently',
      'full': 'FULL',
      'left': 'left',
      'closed': 'Closed',
      'matched': 'Matched',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'view_poster_profile': 'View Pprofile',
      'view_profile': 'View Profile', // NEW
      'save_this_post': 'Save this post',
      'remove_from_saved': 'Remove from saved',
      'copy_details': 'Copy details',
      'edit_post': 'Edit Post',
      'mark_as_done': 'Mark as Done',
      'report_post': 'Report Post',
      'delete_post': 'Delete Post',

      // Toasts / messages // NEW
      'post_closed_toast': 'This post is closed.',
      'already_closed_toast': 'This pasabuy is already closed.',
      'could_not_open_chat': 'Could not open chat',
      'saved_to_favorites': 'Saved to favorites',
      'removed_from_favorites': 'Removed from favorites',
      'could_not_save': 'Could not save',
      'copied_clipboard': 'Copied to clipboard — paste it anywhere!',
      'copied': 'Copied',
      'post_closed_thanks': 'Post closed — thanks!',
      'could_not_close_post': 'Could not close post',
      'post_deleted': 'Post deleted',
      'could_not_delete_post': 'Could not delete post',
      'posted_by': 'Posted by', // NEW
      'via_pasabuy': 'via PasaBuy Mo, Pasaya Ko', // NEW

      // Deals
      'leave_review': 'Leave a Review',
      'rate_this_user': 'Rate This User',
      'my_reviews': 'My Reviews',
      'favorites': 'Favorites',
      'saved_posts': 'Saved Posts',
      'edit_profile': 'Edit Profile',
      'awaiting_accept': 'Awaiting Accept',
      'in_progress': 'In Progress',
      'accept': 'Accept',
      'decline': 'Decline',
      'mark_received': 'Mark Received',
      'mark_delivered': 'Mark Delivered',
      'chat': 'Chat',

      // Auth
      'welcome_back': 'Welcome Back',
      'sign_in_to_continue': 'Sign in to continue to PasaBuy',
      'email': 'Email',
      'password': 'Password',
      'sign_in': 'Sign In',
      'create_account': 'Create Account',
      'create_new_account': 'Create New Account',
      'no_account': 'No account? Register',
      'or': 'OR',

      // Profile screen
      'personal_info': 'Personal Information',
      'my_posts': 'My Posts',
      'no_posts_yet': 'No Posts Yet.',
      'verified_by_admin': 'Verified by Admin',
      'pending_review': 'Pending Review',
      'not_verified': 'Not Verified',

      // Post form
      'new_pasabuy': 'New Pasabuy',
      'im_offering': 'I am offering',
      'im_offering_sub': 'Bring items for others',
      'im_requesting': 'I am requesting',
      'im_requesting_sub': 'Ask for items',
      'title_label': 'Title',
      'title_hint': 'e.g. Pasabuy from Cabagan, Isabela',
      'title_required': 'Title is required',
      'description_label': 'Description',
      'description_hint':
          'What are you offering or looking for? Details help others trust you.',
      'description_required': 'Description is required',
      'from_label': 'From',
      'to_label': 'To',
      'from_hint': 'Cabagan, Isabela',
      'to_hint': 'Tumauini, Isabela',
      'travel_deadline_label': 'Travel / deadline date',
      'pick_date': 'Pick a date (optional)',
      'slots_label': 'Slots (optional)',
      'slots_hint': 'How many buyers can you accept?',
      'slots_helper': 'Leave blank for unlimited. Chat is blocked once full.',
      'slots_error_positive': 'Enter a positive number or leave blank',
      'slots_error_max': 'Max 999',
      'photos_label': 'Photos (up to 5)',
      'add_photo': 'Add',
      'post_published': 'Post published!',
      'failed_to_publish': 'Failed to publish',
      'publish_pasabuy': 'Publish pasabuy',

      // Edit post
      'edit_post_title': 'Edit Post',
      'pick_a_date': 'Pick a date',
      'replace_images': 'Replace images',
      'add_label': 'Add',
      'post_updated': 'Post updated',
      'could_not_update': 'Could not update',
      'save_changes': 'Save Changes',
      'title_required_short': 'Title Required',
      'description_required_short': 'Description Required',

      // My deals / analytics
      'analytics': 'Analytics',
      'view_analytics': 'View Analytics',
      'analytics_subtitle': 'Your deals trend & success rate',
      'no_deals_yet': 'No deals yet',
      'no_deals_sub': 'Deals you start from a chat will appear here.',
      'as_buyer': 'As buyer',
      'as_pasabuyer': 'As pasabuyer',
      'active': 'active',
      'deal_accepted': 'Deal accepted',
      'cancel_deal_title': 'Cancel this deal?',
      'confirm_received_q': 'Confirm you received the item?',
      'confirm_delivered_q': 'Confirm you delivered the item?',
      'confirm_both_sides': 'Both sides must confirm for the deal to complete.',
      'thanks_feedback': 'Thanks for your feedback!',
      'could_not_submit': 'Could not submit',
      'reason_optional': 'Reason (optional)',
      'keep_deal': 'Keep deal',
      'cancel_deal': 'Cancel deal',
      'you_are_buying': 'You are buying',
      'you_are_pasabuyer': 'You are pasabuyer',
      'waiting_for_accept': 'Waiting for accept',
      'waiting': 'Waiting',
      'waiting_for_them': 'Waiting for them',
      'waiting_for_you': 'Waiting for you',
      'buyer_confirmed': 'Buyer confirmed',
      'pasabuyer_confirmed': 'Pasabuyer confirmed',
      'disputed': 'Disputed',
      'how_was_deal': 'How was this deal?',
      'optional_comment': 'Optional comment…',
      'with_user': 'with',
      // Messages placeholder
      'no_messages_yet': 'No messages yet',
      'no_messages_sub': 'Chat with buyers and pasabuyers will appear here.',

      // Chat / conversation
      'chat_title': 'Chat',
      'tap_to_view_profile': 'Tap to view profile',
      'start_a_deal': 'Start a deal',
      'message_hint': 'Message…',
      'could_not_send_image': 'Could not send image',
      'about_this_pasabuy': 'About this pasabuy',

      // Propose deal dialog
      'propose_deal_title': 'Propose a deal',
      'item_description': 'Item description',
      'item_description_hint': 'e.g. Uniqlo jacket size M',
      'agreed_price': 'Agreed price (optional)',
      'notes_optional': 'Notes (optional)',
      'attach_image_optional': 'Attach an image (optional)',
      'propose': 'Propose',
      'item_description_required': 'Item description is required',
      'deal_proposed': 'Deal proposed — waiting for the other side',

      // Messages list
      'start_conversation_hint': 'Start a conversation from any pasabuy post.',

      // Notifications
      'notifications': 'Notifications',
      'mark_all': 'Mark all',
      'no_notifications': 'No notifications',
      'no_notifications_sub': "You'll see updates about your pasabuys here.",
      'just_now': 'Just now',
      'minutes_ago': '{n}m ago',
      'hours_ago': '{n}h ago',
      'days_ago': '{n}d ago',

      // Find screen
      'find_pasabuy_title': 'Find pasabuy',
      'search_items_hint': 'Search items, titles…',
      'location_hint': 'Location',
      'offers': 'Offers',
      'requests': 'Requests',
      'no_results': 'No results. Try different filters.',

      // Favorites screen

      'no_saved_posts': 'No saved posts',
      'no_saved_posts_sub': 'Tap "Save" on any pasabuy to bookmark it here.',

      'admin_fee': 'Admin fee',
      'net_payout': 'Net payout',
      'fee_disclaimer': 'A 2% admin fee is deducted from every completed deal.',
      'you_earn': 'You earn',
      'you_pay': 'Total you pay',

      'download_app': 'Download the App',
    },
    'fil': {
      // Nav
      'home': 'Home',
      'messages': 'Mga Mensahe',
      'transactions': 'Mga Transaksyon',
      'profile': 'Profile',

      // Settings
      'settings': 'Mga Setting',
      'preferences': 'Mga Kagustuhan',
      'language': 'Wika',
      'support': 'Suporta',
      'help_centre': 'Tulong',
      'terms': 'Mga Tuntunin at Kundisyon',
      'about': 'Tungkol sa PasaBuy',
      'account': 'Account',
      'sign_out': 'Mag-log out',
      'delete_account': 'Humiling na burahin ang account',
      'change_password': 'Palitan ang password',
      'change_password_sub': 'I-update ang password ng iyong account',

      // Common actions
      'cancel': 'Kanselahin',
      'confirm': 'Kumpirmahin',
      'save': 'I-save',
      'saved': 'Nai-save',
      'ok': 'OK',
      'yes': 'Oo',
      'no': 'Hindi',
      'loading': 'Naglo-load…',
      'submit': 'Isumite',
      'close': 'Isara',
      'delete': 'Burahin',
      'edit': 'I-edit',
      'view': 'Tingnan',
      'share': 'Ibahagi',
      'copy': 'Kopyahin',
      'report': 'I-report',
      'message': 'Mag-mensahe',
      'search': 'Maghanap',

      // Dialogs
      'logout_title': 'Mag-log out?',
      'logout_body': 'Kailangan mong mag-login muli para magpatuloy.',
      'logout_action': 'Mag-log out',
      'delete_post_title': 'Burahin ang post na ito?',
      'delete_post_body':
          'Makansela ang pasabuy at hindi na ito makikita sa feed.',
      'mark_done_title': 'Markahan na tapos na ang pasabuy?',
      'mark_done_body':
          'Hindi na makakapagpadala ng bagong mensahe ang iba sa post na ito. '
              'Ang mga may usapan na ay maaari pang mag-chat.',
      'mark_done_action': 'Tapos na',

      // Feed
      'search_pasabuy': 'Maghanap ng pasabuy...',
      'post_pasabuy': 'Mag-post ng pasabuy',
      'find_pasabuy': 'Maghanap ng pasabuy',
      'my_deals': 'Aking mga deal',
      'no_pasabuys': 'Wala pang pasabuy',
      'no_pasabuys_sub': 'Maging una sa pag-post ng pasabuy offer o request.',
      'whats_your_pasabuy': 'Ano ang pasabuy mo?',
      'offer': 'Alok',
      'request': 'Kahilingan',
      'photo': 'Larawan',

      // Post card
      'pasabuy_offer': 'Alok na Pasabuy',
      'buy_request': 'Kahilingan',
      'pasa_buy_user': 'PasaBuy User', // NEW
      'you': 'Ikaw',
      'recently': 'Kamakailan',
      'full': 'PUNO',
      'left': 'natitira',
      'closed': 'Sarado',
      'matched': 'May katugon',
      'completed': 'Tapos',
      'cancelled': 'Kinansela',
      'view_poster_profile': 'Tingnan ang profile',
      'view_profile': 'Tingnan ang profile', // NEW
      'save_this_post': 'I-save ang post',
      'remove_from_saved': 'Alisin sa naka-save',
      'copy_details': 'Kopyahin ang detalye',
      'edit_post': 'I-edit ang post',
      'mark_as_done': 'Markahan na tapos',
      'report_post': 'I-report ang post',
      'delete_post': 'Burahin ang post',

      // Toasts / messages // NEW
      'post_closed_toast': 'Sarado na ang post na ito.',
      'already_closed_toast': 'Sarado na ang pasabuy na ito.',
      'could_not_open_chat': 'Hindi mabuksan ang chat',
      'saved_to_favorites': 'Nai-save sa mga paborito',
      'removed_from_favorites': 'Inalis sa mga paborito',
      'could_not_save': 'Hindi mai-save',
      'copied_clipboard': 'Nakopya sa clipboard — i-paste kahit saan!',
      'copied': 'Nakopya',
      'post_closed_thanks': 'Sarado na ang post — salamat!',
      'could_not_close_post': 'Hindi maisara ang post',
      'post_deleted': 'Nabura ang post',
      'could_not_delete_post': 'Hindi mabura ang post',
      'posted_by': 'Ni-post ni', // NEW
      'via_pasabuy': 'sa pamamagitan ng PasaBuy Mo, Pasaya Mo', // NEW

      // Deals
      'leave_review': 'Mag-iwan ng review',
      'rate_this_user': 'I-rate ang user',
      'my_reviews': 'Aking mga review',
      'favorites': 'Mga Paborito',
      'saved_posts': 'Mga naka-save',
      'edit_profile': 'I-edit ang profile',
      'awaiting_accept': 'Hinihintay ang sagot',
      'in_progress': 'Isinasagawa',
      'accept': 'Tanggapin',
      'decline': 'Tanggihan',
      'mark_received': 'Natanggap na',
      'mark_delivered': 'Naibigay na',
      'chat': 'Chat',

      // Auth
      'welcome_back': 'Maligayang pagbabalik',
      'sign_in_to_continue': 'Mag-sign in upang magpatuloy sa PasaBuy',
      'email': 'Email',
      'password': 'Password',
      'sign_in': 'Mag-sign in',
      'create_account': 'Gumawa ng account',
      'create_new_account': 'Gumawa ng bagong account',
      'no_account': 'Walang account? Mag-register',
      'or': 'O',

      // Profile screen
      'personal_info': 'Personal na impormasyon',
      'my_posts': 'Aking mga post',
      'no_posts_yet': 'Wala pang post.',
      'verified_by_admin': 'Beripikado ng admin',
      'pending_review': 'Hinihintay ang pagsusuri',
      'not_verified': 'Hindi pa beripikado',

      // Post form
      'new_pasabuy': 'Bagong pasabuy',
      'im_offering': 'Nag-aalok ako',
      'im_offering_sub': 'Magdadala ng item para sa iba',
      'im_requesting': 'Humihiling ako',
      'im_requesting_sub': 'Naghahanap ng item',
      'title_label': 'Pamagat',
      'title_hint': 'hal. Pasabuy mula sa Cabagan, Isabela',
      'title_required': 'Kailangan ang pamagat',
      'description_label': 'Paglalarawan',
      'description_hint':
          'Ano ang inaalok o hinahanap mo? Ang detalye ay nakakatulong sa tiwala ng iba.',
      'description_required': 'Kailangan ang paglalarawan',
      'from_label': 'Mula sa',
      'to_label': 'Patungo sa',
      'from_hint': 'Cabagan, Isabela',
      'to_hint': 'Tumauini, Isabela',
      'travel_deadline_label': 'Petsa ng paglalakbay / deadline',
      'pick_date': 'Pumili ng petsa (opsyonal)',
      'slots_label': 'Bilang ng tatanggapin (opsyonal)',
      'slots_hint': 'Ilan ang matatanggap mong buyer?',
      'slots_helper':
          'Iwanang blangko kung walang limit. Sarado ang chat kapag puno na.',
      'slots_error_positive': 'Maglagay ng positibong numero o iwanang blangko',
      'slots_error_max': 'Max 999',
      'photos_label': 'Mga larawan (hanggang 5)',
      'add_photo': 'Idagdag',
      'post_published': 'Nai-publish ang post!',
      'failed_to_publish': 'Hindi mai-publish',
      'publish_pasabuy': 'I-publish ang pasabuy',

      // Edit post
      'edit_post_title': 'I-edit ang post',
      'pick_a_date': 'Pumili ng petsa',
      'replace_images': 'Palitan ang mga larawan',
      'add_label': 'Idagdag',
      'post_updated': 'Na-update ang post',
      'could_not_update': 'Hindi ma-update',
      'save_changes': 'I-save ang mga pagbabago',
      'title_required_short': 'Kailangan ang pamagat',
      'description_required_short': 'Kailangan ang paglalarawan',

      // My deals / analytics
      'analytics': 'Mga Estadistika',
      'view_analytics': 'Tingnan ang estadistika',
      'analytics_subtitle': 'Trend ng iyong mga deal at success rate',
      'no_deals_yet': 'Wala pang deal',
      'no_deals_sub': 'Ang mga deal na sisimulan mo sa chat ay lalabas dito.',
      'as_buyer': 'Bilang buyer',
      'as_pasabuyer': 'Bilang pasabuyer',
      'active': 'aktibo',
      'deal_accepted': 'Tinanggap ang deal',
      'cancel_deal_title': 'Kanselahin ang deal na ito?',
      'confirm_received_q': 'Kumpirmahin na natanggap mo ang item?',
      'confirm_delivered_q': 'Kumpirmahin na naibigay mo ang item?',
      'confirm_both_sides':
          'Kailangang kumpirmahin ng dalawang panig para matapos ang deal.',
      'thanks_feedback': 'Salamat sa iyong feedback!',
      'could_not_submit': 'Hindi maisumite',
      'reason_optional': 'Dahilan (opsyonal)',
      'keep_deal': 'Ituloy ang deal',
      'cancel_deal': 'Kanselahin ang deal',
      'you_are_buying': 'Bumibili ka',
      'you_are_pasabuyer': 'Pasabuyer ka',
      'waiting_for_accept': 'Hinihintay ang sagot',
      'waiting': 'Naghihintay',
      'waiting_for_them': 'Hinihintay sila',
      'waiting_for_you': 'Hinihintay ka',
      'buyer_confirmed': 'Kinumpirma ng buyer',
      'pasabuyer_confirmed': 'Kinumpirma ng pasabuyer',
      'disputed': 'May dispute',
      'how_was_deal': 'Kumusta ang deal na ito?',
      'optional_comment': 'Opsyonal na komento…',
      'with_user': 'kasama si',
      // Messages placeholder
      'no_messages_yet': 'Wala pang mensahe',
      'no_messages_sub': 'Dito lalabas ang mga chat sa mga buyer at pasabuyer.',

      // Chat / conversation
      'chat_title': 'Chat',
      'tap_to_view_profile': 'I-tap upang tingnan ang profile',
      'start_a_deal': 'Magsimula ng deal',
      'message_hint': 'Mensahe…',
      'could_not_send_image': 'Hindi maipadala ang larawan',
      'about_this_pasabuy': 'Tungkol sa pasabuy na ito',

      // Propose deal dialog
      'propose_deal_title': 'Mag-propose ng deal',
      'item_description': 'Paglalarawan ng item',
      'item_description_hint': 'hal. Uniqlo jacket size M',
      'agreed_price': 'Napagkasunduang presyo (opsyonal)',
      'notes_optional': 'Mga tala (opsyonal)',
      'attach_image_optional': 'Mag-attach ng larawan (opsyonal)',
      'propose': 'I-propose',
      'item_description_required': 'Kailangan ang paglalarawan ng item',
      'deal_proposed': 'Na-propose ang deal — hinihintay ang kabilang panig',
      // Messages list
      'start_conversation_hint':
          'Magsimula ng usapan mula sa alinmang pasabuy post.',

      // Notifications
      'notifications': 'Mga Notipikasyon',
      'mark_all': 'Markahan lahat',
      'no_notifications': 'Walang notipikasyon',
      'no_notifications_sub':
          'Dito mo makikita ang mga update sa iyong mga pasabuy.',
      'just_now': 'Ngayon lang',
      'minutes_ago': '{n}m ang nakalipas',
      'hours_ago': '{n}h ang nakalipas',
      'days_ago': '{n}d ang nakalipas',

      // Find screen
      'find_pasabuy_title': 'Maghanap ng pasabuy',
      'search_items_hint': 'Maghanap ng item, pamagat…',
      'location_hint': 'Lokasyon',
      'offers': 'Mga Alok',
      'requests': 'Mga Kahilingan',
      'no_results': 'Walang resulta. Subukan ang ibang filter.',

      // Favorites screen
      'no_saved_posts': 'Walang naka-save',
      'no_saved_posts_sub':
          'Pindutin ang "I-save" sa kahit anong pasabuy para ma-bookmark dito.',

      // EN

// FIL
      'admin_fee': 'Bayad sa admin',
      'net_payout': 'Netong kita',
      'fee_disclaimer':
          '2% na bayad sa admin ang ibinabawas sa bawat tapos na deal.',
      'you_earn': 'Kita mo',
      'you_pay': 'Babayaran mo',

            'download_app': 'I-download ang app',
    },
  };

  static String of(BuildContext context, String key) {
    final code = context.watch<LanguageController>().code;
    return _map[code]?[key] ?? _map['en']?[key] ?? key;
  }

  static String ofNum(BuildContext context, String key, int n) {
    final code = context.watch<LanguageController>().code;
    final template = _map[code]?[key] ?? _map['en']?[key] ?? key;
    return template.replaceAll('{n}', '$n');
  }

  static String read(BuildContext context, String key) {
    final code = context.read<LanguageController>().code;
    return _map[code]?[key] ?? _map['en']?[key] ?? key;
  }

  /// Like [ofNum], but safe to call from callbacks.
  static String readNum(BuildContext context, String key, int n) {
    final code = context.read<LanguageController>().code;
    final template = _map[code]?[key] ?? _map['en']?[key] ?? key;
    return template.replaceAll('{n}', '$n');
  }
}

/// Localized date formatter that follows the current language.
class D {
  static String short(BuildContext context, DateTime d) {
    final code = context.watch<LanguageController>().code;
    final locale = code == 'fil' ? 'fil_PH' : 'en_PH';
    return DateFormat.yMMMd(locale).format(d);
  }

  static String long(BuildContext context, DateTime d) {
    final code = context.watch<LanguageController>().code;
    final locale = code == 'fil' ? 'fil_PH' : 'en_PH';
    return DateFormat.yMMMMd(locale).format(d);
  }

  static String time(BuildContext context, DateTime d) {
    final code = context.watch<LanguageController>().code;
    final locale = code == 'fil' ? 'fil_PH' : 'en_PH';
    return DateFormat.Hm(locale).format(d.toLocal());
  }


    /// Like [long], but safe to call from callbacks (no `context.watch`).
  static String readShort(BuildContext context, DateTime d) {
    final code = context.read<LanguageController>().code;
    final locale = code == 'fil' ? 'fil_PH' : 'en_PH';
    return DateFormat.yMMMd(locale).format(d);
  }

  static String readLong(BuildContext context, DateTime d) {
    final code = context.read<LanguageController>().code;
    final locale = code == 'fil' ? 'fil_PH' : 'en_PH';
    return DateFormat.yMMMMd(locale).format(d);
  }

  static String readTime(BuildContext context, DateTime d) {
    final code = context.read<LanguageController>().code;
    final locale = code == 'fil' ? 'fil_PH' : 'en_PH';
    return DateFormat.Hm(locale).format(d.toLocal());
  }
}

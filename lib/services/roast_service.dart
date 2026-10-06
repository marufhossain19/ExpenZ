import 'dart:math';

/// AI Roast Service — generates witty, sarcastic comments
/// about user spending habits. Income gets encouragement instead.
class RoastService {
  static final _random = Random();

  /// Get a roast message based on category and amount spent.
  /// Higher amounts trigger harsher roasts.
  static String getRoast(String category, double amount, {bool isIncome = false}) {
    if (isIncome) return _getEncouragement(category, amount);

    final roasts = _roastsByCategory[category.toLowerCase()] ?? _genericRoasts;

    // Higher amounts → pick from the harsher end of the list
    final intensity = amount > 5000
        ? roasts.length - 1
        : amount > 1000
            ? (roasts.length * 0.7).toInt()
            : _random.nextInt(roasts.length);

    final index = intensity.clamp(0, roasts.length - 1);
    return roasts[index];
  }

  /// Encouraging messages for income entries
  static String _getEncouragement(String category, double amount) {
    final msgs = [
      'Money coming in! You love to see it 💰',
      'Cha-ching! Your wallet is breathing again 🎉',
      'Finally, some income! Almost forgot what that looks like 😏',
      'The hustle is paying off! Keep grinding 💪',
      'Your bank account just did a happy dance 🕺',
      'Look at you, being all productive and stuff! 🌟',
      'More money, fewer problems... in theory 😄',
      'Your future self is thanking you right now 🙏',
    ];
    return msgs[_random.nextInt(msgs.length)];
  }

  // ── Category-specific roasts (sorted mild → harsh) ──────

  static final Map<String, List<String>> _roastsByCategory = {
    'food': [
      'Home-cooked meals exist, you know 🍳',
      'Your kitchen is crying from neglect 😢',
      'At this rate, you\'re funding someone else\'s retirement 🍕',
      'Do you even OWN a stove? Asking for your wallet 🔥',
      'Bro, ramen exists. It\'s literally ৳20 a packet 🍜',
      'Gordon Ramsay would roast you harder than your spending 🤦',
      'Your food budget could feed a small village 💀',
    ],
    'shopping': [
      'Did you NEED that, or did Instagram tell you to? 🛍️',
      'Your closet is screaming for help right now 👗',
      'Another "treat yourself" moment? Your wallet disagrees 💳',
      'This is why your savings account has trust issues 😤',
      'Congrats, you just bought happiness... for 5 minutes ⏰',
      'Amazon should name a warehouse after you at this point 📦',
      'You don\'t have a shopping habit, you have a shopping CAREER 💀',
    ],
    'transport': [
      'Walking is free AND it\'s exercise 🚶',
      'Your legs work, right? Just checking 🦵',
      'At this rate, just buy the whole Uber company 🚗',
      'Petition to rename ride-sharing apps to "your money-burning apps" 🔥',
      'Your transport costs could lease a helicopter 🚁',
    ],
    'bills': [
      'Adulting is expensive, huh? 😅',
      'The bills... they never stop coming 📬',
      'Your utility companies are having a great month thanks to you ⚡',
      'Have you tried living by candlelight? Very aesthetic 🕯️',
      'At this rate, you\'re basically a bill-paying machine 🤖',
    ],
    'entertainment': [
      'Living your best life on a budget... wait, what budget? 🎬',
      'Netflix AND chill AND Spotify AND gaming? Pick a struggle 🎮',
      'Your entertainment budget has its own entertainment budget 🎪',
      'Touch grass. It\'s free content 🌿',
      'You\'re not living, you\'re just subscribing to everything 💸',
      'Your subscriptions have subscriptions at this point 📱',
    ],
    'health': [
      'At least you\'re investing in yourself! 💊',
      'Health is wealth... but this is getting expensive 🏥',
      'Your body is a temple and the maintenance costs are WILD 🏋️',
      'Maybe try not getting sick? Just a thought 🤒',
      'Have you tried drinking water and going to bed early? 💧',
    ],
  };

  static final List<String> _genericRoasts = [
    'Interesting choice... your wallet is judging you 👀',
    'Was this absolutely necessary? Be honest 🤔',
    'Your savings account just filed a police report 🚨',
    'Money well spent... said no financial advisor ever 📊',
    'Your bank balance is giving ✨trauma✨ vibes 😬',
    'Future you is going to be SO disappointed 📉',
    'This purchase has "I\'ll regret this later" energy 🫠',
    'Congratulations, you just set your financial goals back a week 🎊',
  ];
}

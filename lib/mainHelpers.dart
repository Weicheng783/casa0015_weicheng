import 'dart:core';

String getGreeting() {
  DateTime now = DateTime.now();

  if (now.hour >= 0 && now.hour <= 5) {
    return "Good Night 🌜💤";
  } else if (now.hour >= 6 && now.hour <= 8) {
    return "Good Morning 🌞💫";
  } else if (now.hour >= 9 && now.hour <= 11) {
    return "Good Morning 🌞💫";
  } else if (now.hour >= 12 && now.hour <= 17) {
    return "Good Afternoon 🌝";
  } else if (now.hour >= 18 && now.hour <= 23) {
    return "Good Evening 🌠";
  } else {
    return "Good Morning 🌞💫"; // Strange Corner Case
  }
}
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

final List<String> encouragementSentences = [
  "Embrace the power of your memories and share the magic they hold.",
  "Your stories have the potential to inspire and uplift others. Share them with the world.",
  "Every memory is a chapter in the book of your life. Open up and let others read the beautiful stories within.",
  "Explore the vast tapestry of your memories and uncover the treasures hidden within them.",
  "In every story lies a lesson. Share yours and contribute to the collective wisdom of humanity.",
  "The world is waiting to hear the unique melody of your experiences. Don't keep it to yourself.",
  "Each memory is a spark of light. Share them, and together we can create a dazzling constellation of stories.",
  "Let your memories be the compass guiding others on their journey through life.",
  "The more we share, the richer our collective tapestry of stories becomes. Be a part of this beautiful mosaic.",
  "Your memories are like seeds. Plant them in the hearts of others and watch them bloom into inspiration.",
  "The world is a canvas, and your stories are the brushstrokes that add color and depth to the masterpiece.",
  "Unlock the doors of your memories and invite others to explore the enchanting corridors of your life.",
  "Each story shared is a bridge connecting hearts and minds. Build connections through your experiences.",
  "Your memories are a treasure trove. Share them generously, and watch the wealth of human experience grow.",
  "Life is an adventure, and your stories are the maps that guide others through uncharted territories.",
  "Don't just reminisce; share the magic of your memories. You never know whose heart you might touch.",
  "The world is a book, and those who do not share their stories read only one page. Open your book wide.",
  "Your stories have the power to heal, inspire, and transform. Share them with kindness and authenticity.",
  "Every memory is a thread, weaving the fabric of our shared human experience. Contribute your thread.",
  "Step outside the familiar and explore the unknown. Your stories may be the guide someone else is seeking."
];
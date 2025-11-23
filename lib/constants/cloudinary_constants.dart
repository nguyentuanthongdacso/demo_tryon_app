class CloudinaryConstants {
  // Cloudinary configuration
  static const String cloudName = 'dcq6kbxpg';
  static const String apiKey = '366287123542277';
  static const String apiSecret = 'dTuz6cfhafLkA7hHQpLvbKpzwZs';
  
  // Upload endpoint
  static String get uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  
  // Upload preset for unsigned uploads (created in Cloudinary dashboard)
  static const String uploadPreset = 'demo_tryon';
}

class ApiConstants {
  // Auth endpoints (Backend2-NestJS-Gateway)
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/me';
  static const String health = '/health';

  // GraphQL & Subscriptions (Backend1-Java-Negocio via Gateway)
  static const String graphql = '/graphql';
  static const String subscriptions = '/subscriptions';
  static const String wsNotifications = '/ws';

  // REST Gateway endpoints (CU3: Cotizaciones, CU6: Pagos, Uploads)
  static const String quotations = '/api/quotations';
  static const String payments = '/api/payments';
  static const String cloudinarySignature = '/api/uploads/cloudinary-signature';
  static const String uploadS3 = '/api/uploads/s3';

  // Marketplace (CRUD de muebles + checkout directo)
  static const String marketplaceProducts = '/api/products';
  static const String marketplaceCheckout = '/api/products/checkout';

  // Facturación / Recibos PDF (CU5: Backend4-PHP-Recibos via Gateway)
  static const String invoices = '/api/invoices';

  // Inteligencia Artificial & MCP (CU1, CU3, CU4, CU7: Backend3-Python-IA-MCP via Gateway)
  static const String aiEstimate = '/api/ai/estimate';
  static const String aiAgent = '/api/ai/agent';
  static const String aiReport = '/api/ai/report';
  static const String aiClusterClients = '/api/ai/cluster-clients';
  static const String aiDeliveryCheck = '/api/ai/delivery/check';
  static const String aiTts = '/api/ai/tts';

  // Legacy endpoints (compatibilidad)
  static const String products = '/productos';
  static const String categories = '/categorias';
  static const String orders = '/pedidos';
  static const String materials = '/materiales';
  static const String voiceReports = '/reportes-voz';

  // Timeouts
  static const Duration timeout = Duration(seconds: 10);
  static const Duration aiTimeout = Duration(seconds: 25);
}

class SqlSecurityValidator {
  static final RegExp _forbiddenKeywords = RegExp(
    r'\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|REPLACE|TRUNCATE|ATTACH|DETACH|PRAGMA|VACUUM|TRANSACTION|COMMIT|ROLLBACK|GRANT|REVOKE| SQLITE_MASTER | SQLITE_TEMP_MASTER)\b',
    caseSensitive: false,
  );

  static final Set<String> _allowedTables = {
    'pedidos',
    'productos',
    'materiales',
  };

  /// Limpia la petición del usuario antes de enviarla al LLM para mitigar
  /// intentos de Prompt Injection (ej. "Ignora las instrucciones anteriores...").
  static String sanitizeUserPrompt(String input) {
    var cleaned = input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('```', '')
        .trim();

    if (cleaned.length > 400) {
      cleaned = cleaned.substring(0, 400);
    }

    // Bloquea frases típicas de jailbreak / prompt injection
    final injectionPatterns = RegExp(
      r'(ignora\s+(todas\s+)?las\s+instrucciones|ignore\s+previous\s+instructions|system\s+prompt|drop\s+table|delete\s+from|update\s+set)',
      caseSensitive: false,
    );
    if (injectionPatterns.hasMatch(cleaned)) {
      throw Exception(
        'Alerta de Seguridad: Se detectó un intento de inyección de instrucciones no permitido.',
      );
    }

    return cleaned;
  }

  /// Extrae la consulta SQL de la respuesta del LLM y valida estrictamente
  /// que sea una consulta SELECT de solo lectura sobre las tablas permitidas.
  static String extractAndValidateSql(String llmRawOutput) {
    // 1. Eliminar bloques <think>...</think> propios de modelos Qwen3
    var text = llmRawOutput.replaceAll(
      RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
      '',
    ).trim();

    // 2. Extraer contenido si viene dentro de bloque ```sql ... ```
    final codeBlockMatch = RegExp(
      r'```(?:sql)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(text);
    if (codeBlockMatch != null) {
      text = codeBlockMatch.group(1)!.trim();
    }

    // 3. Buscar desde el primer SELECT
    final selectIndex = text.toUpperCase().indexOf('SELECT ');
    if (selectIndex != -1) {
      text = text.substring(selectIndex).trim();
    }

    // Cortar en el primer salto de línea doble o punto y coma final
    if (text.contains(';')) {
      text = text.split(';').first.trim();
    }

    // 4. Validaciones de seguridad estrictas
    if (text.isEmpty || !text.toUpperCase().startsWith('SELECT ')) {
      throw Exception(
        'Seguridad SQL: El modelo no generó una sentencia SELECT válida.',
      );
    }

    if (text.contains('--') || text.contains('/*') || text.contains('*/')) {
      throw Exception(
        'Seguridad SQL: Comentarios SQL bloqueados por prevención de inyección.',
      );
    }

    if (_forbiddenKeywords.hasMatch(text)) {
      throw Exception(
        'Seguridad SQL: Se bloqueó una instrucción de modificación o sistema no autorizada.',
      );
    }

    // 5. Verificar que solo consulte tablas autorizadas de la carpintería
    final fromMatches = RegExp(
      r'\b(?:FROM|JOIN)\s+([a-zA-Z0-9_]+)',
      caseSensitive: false,
    ).allMatches(text);

    if (fromMatches.isEmpty) {
      throw Exception('Seguridad SQL: La consulta debe especificar una tabla válida.');
    }

    for (final match in fromMatches) {
      final table = match.group(1)!.toLowerCase();
      if (!_allowedTables.contains(table)) {
        throw Exception(
          'Seguridad SQL: Acceso denegado a la tabla "$table". Solo se permite consultar: ${_allowedTables.join(", ")}.',
        );
      }
    }

    // 6. Asegurar límite máximo de filas para proteger memoria
    if (!RegExp(r'\bLIMIT\s+\d+', caseSensitive: false).hasMatch(text)) {
      text = '$text LIMIT 100';
    }

    return text;
  }

  /// Genera una consulta SQL segura de respaldo (fallback determinista) si el
  /// usuario hace una consulta rápida o si el LLM aún no fue cargado.
  static String fallbackSqlForQuery(String userQuery) {
    final q = userQuery.toLowerCase();

    if (q.contains('material') ||
        q.contains('madera') ||
        q.contains('stock') ||
        q.contains('inventario') ||
        q.contains('insumo')) {
      if (q.contains('bajo') || q.contains('alerta') || q.contains('falt')) {
        return 'SELECT id, nombre, tipo, cantidad, unidad, stock_minimo, costo_unitario FROM materiales WHERE cantidad <= stock_minimo LIMIT 100';
      }
      return 'SELECT id, nombre, tipo, cantidad, unidad, stock_minimo, costo_unitario FROM materiales LIMIT 100';
    }

    if (q.contains('producto') ||
        q.contains('catalogo') ||
        q.contains('catálogo') ||
        q.contains('mueble') ||
        q.contains('precio')) {
      return 'SELECT id, nombre, categoria, tipo_madera, dimensiones, precio, stock FROM productos LIMIT 100';
    }

    // Por defecto consulta la tabla de pedidos
    if (q.contains('pendiente')) {
      return "SELECT id, cliente_nombre, producto_nombre, tipo_madera, monto_total, adelanto, saldo, estado, fecha_entrega FROM pedidos WHERE estado = 'Pendiente' LIMIT 100";
    }
    if (q.contains('fabricaci')) {
      return "SELECT id, cliente_nombre, producto_nombre, tipo_madera, monto_total, adelanto, saldo, estado, fecha_entrega FROM pedidos WHERE estado = 'En fabricación' LIMIT 100";
    }
    if (q.contains('listo') || q.contains('entregado')) {
      return "SELECT id, cliente_nombre, producto_nombre, tipo_madera, monto_total, adelanto, saldo, estado, fecha_entrega FROM pedidos WHERE estado IN ('Listo', 'Entregado') LIMIT 100";
    }
    if (q.contains('roble')) {
      return "SELECT id, cliente_nombre, producto_nombre, tipo_madera, monto_total, adelanto, saldo, estado, fecha_entrega FROM pedidos WHERE tipo_madera LIKE '%Roble%' LIMIT 100";
    }
    if (q.contains('cedro')) {
      return "SELECT id, cliente_nombre, producto_nombre, tipo_madera, monto_total, adelanto, saldo, estado, fecha_entrega FROM pedidos WHERE tipo_madera LIKE '%Cedro%' LIMIT 100";
    }

    return 'SELECT id, cliente_nombre, producto_nombre, tipo_madera, monto_total, adelanto, saldo, estado, fecha_entrega FROM pedidos LIMIT 100';
  }
}

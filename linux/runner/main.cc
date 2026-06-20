#include "my_application.h"
#include <string.h>

static void custom_log_handler(const gchar* log_domain,
                               GLogLevelFlags log_level,
                               const gchar* message,
                               gpointer user_data) {
  if (message && strstr(message, "ibus_attr_list_copy_format_to_rgba") != nullptr) {
    return; // Suppress
  }
  g_log_default_handler(log_domain, log_level, message, user_data);
}

static GLogWriterOutput custom_log_writer(GLogLevelFlags log_level,
                                          const GLogField *fields,
                                          gsize n_fields,
                                          gpointer user_data) {
  for (gsize i = 0; i < n_fields; i++) {
    if (strcmp(fields[i].key, "MESSAGE") == 0) {
      const char* msg = static_cast<const char*>(fields[i].value);
      if (msg && strstr(msg, "ibus_attr_list_copy_format_to_rgba") != nullptr) {
        return G_LOG_WRITER_HANDLED;
      }
    }
  }
  return g_log_writer_default(log_level, fields, n_fields, user_data);
}

int main(int argc, char** argv) {
  g_log_set_default_handler(custom_log_handler, nullptr);
  g_log_set_writer_func(custom_log_writer, nullptr, nullptr);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}


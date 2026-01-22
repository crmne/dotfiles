#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int PRRawGetRawConversionPlugIns(void *buffer, uint64_t buffer_size,
                                 uint32_t api_version, uint32_t flags,
                                 uint32_t *out_count, void *out_error) {
  (void)buffer;
  (void)buffer_size;
  (void)api_version;
  (void)flags;
  (void)out_error;
  if (out_count) {
    *out_count = 0;
  }
  return 0;
}

int PRRawGetRawConversionPlugInLoadingErrorInfo(void *buffer,
                                                uint64_t buffer_size,
                                                uint32_t api_version,
                                                uint32_t flags,
                                                uint32_t *out_count,
                                                void *out_error) {
  (void)buffer;
  (void)buffer_size;
  (void)api_version;
  (void)flags;
  (void)out_error;
  if (out_count) {
    *out_count = 0;
  }
  return 0;
}

#ifdef __cplusplus
}
#endif

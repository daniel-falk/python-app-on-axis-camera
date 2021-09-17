#include <dummy_data.h>
#include <malloc.h>
#include <inttypes.h>

uint8_t *get_numbers(int len) {
    uint8_t *data = malloc(len);
    for (int i = 0; i < len; i++) {
        data[i] = i*i;
    }
    return data;
}

void free_numbers(uint8_t *data) {
    free(data);
}

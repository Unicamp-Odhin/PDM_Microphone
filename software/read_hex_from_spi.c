#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/spi/spidev.h>

#define DEVICE "/dev/spidev1.0"
#define DELAY 0
#define READ_SIZE 524288*4 // Número total de bytes a serem lidos (deve ser par)
#define PAGE_SIZE 4096     // Tamanho máximo de leitura por operação

// Variáveis globais
static uint32_t SPEED = 3072000;
static uint8_t BITS_PER_WORD = 8;
static uint8_t MODE = 0;

static void pabort(const char *s)
{
    perror(s);
    abort();
}

static void read_and_save(int fd, const char *filename)
{
    FILE *out = fopen(filename, "w");
    if (!out)
        pabort("Erro ao abrir arquivo para escrita");

    size_t remaining = READ_SIZE;
    size_t offset = 0;

    while (remaining > 0) {
        size_t chunk_size = remaining > PAGE_SIZE ? PAGE_SIZE : remaining;

        // Garantir que chunk_size seja par para formar os pares de 2 bytes
        if (chunk_size % 2 != 0)
            chunk_size--;

        uint8_t *rx = calloc(chunk_size, 1);
        if (!rx)
            pabort("Erro de alocação");

        struct spi_ioc_transfer tr = {
            .tx_buf = 0,
            .rx_buf = (unsigned long)rx,
            .len = chunk_size,
            .delay_usecs = DELAY,
            .speed_hz = SPEED,
            .bits_per_word = BITS_PER_WORD,
        };

        int ret = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
        if (ret < 1) {
            free(rx);
            pabort("Erro ao enviar mensagem SPI");
        }

        // Salvar pares como 16 bits em hexadecimal
        for (size_t i = 0; i + 1 < chunk_size; i += 2) {
            uint16_t sample = rx[i] | (rx[i + 1] << 8);
            fprintf(out, "%04X\n", sample);
        }

        free(rx);
        offset += chunk_size;
        remaining -= chunk_size;
    }

    fclose(out);
}

int main(void)
{
    int fd, ret;

    fd = open(DEVICE, O_RDWR);
    if (fd < 0)
        pabort("Não foi possível abrir o dispositivo SPI");

    // Configurações do modo SPI
    ret = ioctl(fd, SPI_IOC_WR_MODE, &MODE);
    if (ret == -1)
        pabort("Não foi possível definir o modo SPI");

    ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &BITS_PER_WORD);
    if (ret == -1)
        pabort("Não foi possível definir os bits por palavra");

    ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &SPEED);
    if (ret == -1)
        pabort("Não foi possível definir a velocidade SPI");

    printf("Dispositivo: %s\n", DEVICE);
    printf("Modo SPI: %d\n", MODE);
    printf("Bits por palavra: %d\n", BITS_PER_WORD);
    printf("Velocidade máxima: %d Hz\n", SPEED);

    read_and_save(fd, "dump.hex");

    close(fd);
    return 0;
}

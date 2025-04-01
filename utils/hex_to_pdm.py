import matplotlib.pyplot as plt
from matplotlib.widgets import Slider


def hex_to_bin(hex_str):
    # Converte um valor hexadecimal para uma string binária de tamanho fixo (16 bits)
    return bin(int(hex_str, 16))[2:].zfill(16)


def read_hex_file(filename):
    # Lê o arquivo e converte cada linha em binário
    pdm_bits = []
    with open(filename, 'r') as file:
        for line in file:
            hex_value = line.strip()
            if hex_value:
                bin_value = hex_to_bin(hex_value)
                pdm_bits.extend([int(bit) for bit in bin_value])
    return pdm_bits


def plot_pdm(pdm_bits, window_size=1000):
    # Configura o gráfico
    fig, ax = plt.subplots()
    plt.subplots_adjust(bottom=0.25)

    # Mostra apenas uma janela do sinal
    l, = plt.plot(pdm_bits[:window_size], linestyle='-', marker='', color='blue')
    ax.set_title('Sinal PDM Extraído do Arquivo HEX')
    ax.set_xlabel('Amostra')
    ax.set_ylabel('Nível PDM (0 ou 1)')
    ax.grid(True)

    # Adiciona um slider para navegar
    ax_slider = plt.axes([0.25, 0.1, 0.65, 0.03])
    slider = Slider(ax_slider, 'Posição', 0, len(pdm_bits) - window_size, valinit=0, valstep=1)

    def update(val):
        pos = int(slider.val)
        l.set_ydata(pdm_bits[pos:pos + window_size])
        l.set_xdata(range(pos, pos + window_size))
        ax.relim()
        ax.autoscale_view()
        plt.draw()

    slider.on_changed(update)

    plt.show()


def main():
    # Nome do arquivo .hex
    filename = 'audios/output.hex'

    # Lê o arquivo e obtém os bits PDM
    pdm_bits = read_hex_file(filename)

    # Plota o sinal PDM
    plot_pdm(pdm_bits, window_size=1000)


if __name__ == "__main__":
    main()

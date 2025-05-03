import numpy as np
import matplotlib.pyplot as plt


def blackman_window(M):
    n = np.arange(0, M)
    w = (
        0.42
        - 0.5 * np.cos((2 * np.pi * n) / M)
        + 0.08 * np.cos((4 * np.pi * n) / M)
    )
    return w


# Exemplo de uso
M = 64
w = blackman_window(M)

# Imprimindo os coeficientes como lista
print('Coeficientes da janela de Blackman:')
print(w.tolist())

# Plotando a janela
plt.plot(w)
plt.title(f'Janela de Blackman (M = {M})')
plt.xlabel('n')
plt.ylabel('w(n)')
plt.grid(True)
plt.show()

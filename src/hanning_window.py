import numpy as np
import matplotlib.pyplot as plt


def hanning_window(M):
    n = np.arange(0, M)
    w = 0.5 - 0.5 * np.cos((2 * np.pi * n) / M)
    return w


# Parâmetro M
M = 64

# Calcula a janela de Hanning
w = hanning_window(M)

# Imprime os coeficientes
print('Coeficientes da janela de Hanning:')
print(w.tolist())

# Plota a janela
plt.figure(figsize=(10, 4))
plt.plot(w, marker='o')
plt.title(f'Janela de Hanning (M = {M})')
plt.xlabel('n')
plt.ylabel('w(n)')
plt.grid(True)
plt.tight_layout()
plt.show()

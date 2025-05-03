import numpy as np
import matplotlib.pyplot as plt


def bartlett_window(M):
    n = np.arange(0, M)
    w = 1 - (2 * np.abs(n - M / 2)) / M
    return w


# Parâmetro M
M = 64

# Calcula a janela de Bartlett
w = bartlett_window(M)

# Imprime os coeficientes
print('Coeficientes da janela de Bartlett:')
print(w.tolist())

# Plota a janela
plt.figure(figsize=(10, 4))
plt.plot(w, marker='o')
plt.title(f'Janela de Bartlett (M = {M})')
plt.xlabel('n')
plt.ylabel('w(n)')
plt.grid(True)
plt.tight_layout()
plt.show()

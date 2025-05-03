import numpy as np
import matplotlib.pyplot as plt


def hamming_window(M):
    n = np.arange(0, M)
    w = 0.54 - 0.46 * np.cos((2 * np.pi * n) / M)
    return w


# Parâmetro M
M = 64

# Calcula a janela de Hamming
w = hamming_window(M)

# Imprime os coeficientes
print('Coeficientes da janela de Hamming:')
print(w.tolist())

# Plota a janela
plt.figure(figsize=(10, 4))
plt.plot(w, marker='o')
plt.title(f'Janela de Hamming (M = {M})')
plt.xlabel('n')
plt.ylabel('w(n)')
plt.grid(True)
plt.tight_layout()
plt.show()

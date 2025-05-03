import numpy as np
import matplotlib.pyplot as plt
from scipy.special import i0


def kaiser_window(M, beta=0.0):
    n = np.arange(0, M)
    alpha = (M - 1) / 2  # Centro da janela
    a = M / 2  # Largura
    w = i0(beta * np.sqrt(1 - ((n - alpha) / a) ** 2)) / i0(beta)
    return w


# Parâmetro M
M = 64
beta = 5.0  # Parâmetro beta da janela de Kaiser

# Calcula a janela de Kaiser
w = kaiser_window(M, beta)

# Imprime os coeficientes
print('Coeficientes da janela de Kaiser:')
print(w.tolist())

# Plota a janela
plt.figure(figsize=(10, 4))
plt.plot(w, marker='o')
plt.title(f'Janela de Kaiser (M = {M})')
plt.xlabel('n')
plt.ylabel('w(n)')
plt.grid(True)
plt.tight_layout()
plt.show()

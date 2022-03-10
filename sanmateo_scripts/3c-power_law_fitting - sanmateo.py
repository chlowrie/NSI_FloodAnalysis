#https://towardsdatascience.com/basic-curve-fitting-of-scientific-data-with-python-9592244a2509
#https://static-content.springer.com/esm/art%3A10.1038%2Fs41598-020-61136-6/MediaObjects/41598_2020_61136_MOESM1_ESM.pdf
#%%

from scipy.optimize import curve_fit
import numpy as np
import matplotlib
import matplotlib.pyplot as plt

# Helps to pretty print large $$$ values 
def kFormatter(x):
    if x >= 1000000000:
        return '$' + str(round(x / 1000000000.0)) + 'B'
    if x >= 1000000:
        return '$' + str(round(x / 1000000.0)) + 'M'
    if x >= 1000:
        return '$' + str(round(x / 1000.0)) + 'K'
    else:
        return '$' + str(round(x))

# Used to hardcode y axis ticks
labels = [
    0,
    100_000_000,
    200_000_000,
    300_000_000,
    400_000_000,
    500_000_000,
    600_000_000,
    700_000_000,
    800_000_000
]

expected_damages = {
    'restored': [
        [1, 577265532.978651],
        [20, 565736435.5644119],
        # [20, 585736435.5644119],
        # [80, 595736435.5644119],
        [100, 693987045.0368384]
    ],
    'existing': [
        [1, 595896839.958807],
        [20, 581277087.867979],
        # [20, 601277087.867979],
        # [80, 611277087.867979],
        [100, 728920221.2438828]
    ]
}



# Function to calculate the power-law with constants a and b
def power_law(x, a, b):
    return a*np.power(x, b)

_restored = expected_damages['restored']
_existing = expected_damages['existing']

plt.plot(
    [i[0] for i in _restored],
    [i[1] for i in _restored]
)

plt.plot(
    [i[0] for i in _existing],
    [i[1] for i in _existing]
)

plt.show()
# %%

pars_restored, cov_restored = curve_fit(
    f=power_law,
    xdata = [i[0] for i in _restored],
    ydata = [i[1] for i in _restored],
    p0 = [10,10],
    bounds=(-np.inf, np.inf)
)

print('RESTORED: {}*{}^{}'.format(pars_restored[0], 'x', pars_restored[1]))

pars_existing, cov_existing = curve_fit(
    f=power_law,
    xdata = [i[0] for i in _existing],
    ydata = [i[1] for i in _existing],
    p0 = [10,10],
    bounds=(-np.inf, np.inf)
)


print('EXISTING: {}*{}^{}'.format(pars_existing[0], 'x', pars_existing[1]))

x_dummy = np.linspace(start=1, stop=100, num=100)
y_dummy_restored = power_law(x_dummy, *pars_restored)
y_dummy_existing = power_law(x_dummy, *pars_existing)

fig, ax = plt.subplots()


ax.plot(
    x_dummy,
    y_dummy_restored,
    '#7bccc4',
    label='Restored'
)

ax.plot(
    x_dummy,
    y_dummy_existing,
    '#0868ac',
    label='Existing'
)

print([i[0] for i in _restored])
print([i[1] for i in _restored])
ax.scatter(
    [i[0] for i in _restored],
    [i[1] for i in _restored],
    c='#7bccc4',
    marker='x'
)

ax.scatter(
    [i[0] for i in _existing],
    [i[1] for i in _existing],
    c='#0868ac',
    marker='x'
)

plt.title('Fitted Power Law')
plt.ylabel('Damages')
plt.xlabel('Return Period')

ylabels = [kFormatter(label) for label in labels]
plt.yticks(labels, ylabels)

plt.show()
# %%



plt.xlabel('Return Period')
ylabels = [kFormatter(label) for label in labels]
plt.yticks(labels, ylabels)
plt.ylabel('Expected Damages')
# ax.yaxis.set_major_formatter(matplotlib.ticker.StrMethodFormatter('{x:,.0f}'))
plt.title('Fitting Expected Damages')
plt.legend()
plt.savefig('FittedDamages.png')
plt.show()

#%%

y_dummy_likelihood = 1/x_dummy
labels2 = [0, .50, 1.00]

fig, ax = plt.subplots()
def formattedP(p):
    return str(p*100) + '%'
ylabels2 = [formattedP(label) for label in labels2]
plt.yticks(labels2, ylabels2)
plt.ylabel('p')
plt.xlabel('Return Period')
# ax.yaxis.set_major_formatter(matplotlib.ticker.StrMethodFormatter('{x:,.0f}'))
plt.title('Annual Storm Likelihood')
# plt.legend()

ax.plot(
    x_dummy,
    y_dummy_likelihood,
    'k:',
    label='Likelihood'
)
plt.savefig('Likelihoods.png')
plt.show()
#%%

fig, ax = plt.subplots() 
y_ae = (y_dummy_existing - y_dummy_restored) * y_dummy_likelihood
print(y_ae)
ax.plot(
    x_dummy,
    y_ae,
    '#0868ac',
    label='Likelihood'
)

labels = [
    0,
    10_000_000,
    20_000_000
]

ylabels = [kFormatter(label) for label in labels]
plt.yticks(labels, ylabels)
plt.title('Annual Expected Benefit')
plt.xlabel('Return Period')
plt.ylabel('AEB')
plt.savefig('AEB.png')
plt.show()

#%%
a_restored,b_restored = pars_restored
a_existing,b_existing = pars_existing

def aed_integral(p, a, b):
    return a * np.power(p, -b+1) / (-b+1)

aed_restored = aed_integral(1, a_restored, b_restored) - \
    aed_integral(.01, a_restored, b_restored)

aed_existing = aed_integral(1, a_existing, b_existing) - \
    aed_integral(.01, a_existing, b_existing)

print(aed_existing - aed_restored)
#%%
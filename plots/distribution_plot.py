import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from matplotlib.patches import Patch

deep_red = '#b2182bff'
salmon = '#ef8a62ff'
skintone = '#fddbc7'
blue = '#2166ac'


def set_tex():
    plt.rcParams.update({
        'text.usetex': True,
        'font.family': 'serif',
        'font.serif': ['Computer Modern Roman'],
        'font.size': 17,
    })


def plotter(sizes, models, labels_cleaned, save_file=None, height=3.333):
    maxx = 20
    sizes, models, labels_cleaned = sizes[:maxx], models[:maxx], labels_cleaned[:maxx]

    set_tex()

    bar_width = 0.3  # Narrower bars to fit two side by side
    maxy = max(sizes + models)
    offset = maxy / 100

    fig, ax = plt.subplots(figsize=(8, height))
    ax.yaxis.set_major_formatter(ticker.StrMethodFormatter('{x:,g}'))

    # Plot the first set of bars (sizes)
    bars1 = ax.bar(
        [i - bar_width/2 for i in range(maxx)],
        sizes,
        color=deep_red,  # Deep red for sizes
        width=bar_width,
        zorder=3,
        label='Frequency'
    )

    # Plot the second set of bars (models)
    bars2 = ax.bar(
        [i + bar_width/2 for i in range(maxx)],
        models,
        color=salmon,  # Deep red for models
        width=bar_width,
        zorder=3,
        label='Models'
    )

    ax.yaxis.grid(True, linestyle='--', which='major', color='gray', alpha=0.75, zorder=0)
    ax.xaxis.grid(False)
    ax.set_xticks(range(maxx))
    ax.set_xticklabels(labels_cleaned, rotation=90, fontsize=17)
    ax.set_ylabel("Count")

    # Adjust y-axis limit
    ax.set_ylim(0, maxy + 10 * offset)

    # Simplified legend
    legend_elements = [
        Patch(facecolor=deep_red, label='Subsystems'),
        Patch(facecolor=salmon, label='Models')
    ]

    legend = ax.legend(
        handles=legend_elements,
        loc='upper right',
        #title='Metrics',
        fontsize=14
    )
    plt.setp(legend.get_title(), ha='center')

    plt.tight_layout()
    if save_file is not None:
        plt.savefig(save_file+".pdf", bbox_inches='tight', format='pdf')
    plt.show()

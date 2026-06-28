# Getting Started

## Prerequisites

- **Julia 1.9+**: [Download](https://julialang.org/downloads/)
- **Gurobi Optimizer**: [Free academic license available](https://www.gurobi.com/academia/academic-program-and-licenses/)
- **Gurobi License**: Set up your `gurobi.lic` file in your home directory or configure `GUROBI_HOME` environment variable

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Rajas124/Airline-Crew-Pairing-Optimization.git
cd Airline-Crew-Pairing-Optimization
```

### 2. Install Julia Dependencies

```bash
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

This will install:
- **JuMP** – Mathematical Optimization framework
- **Gurobi.jl** – Interface to Gurobi solver
- **Dates** & **Random** – Standard library modules

### 3. Verify Gurobi Installation

```bash
julia -e "using Gurobi; println(Gurobi.GurobiVersionInfo())"
```

If successful, you'll see Gurobi version information. If you get an error, ensure:
- Gurobi is installed correctly
- License file is in place
- `GUROBI_HOME` environment variable is set (if needed)

## Quick Start

### Run the Solver

```bash
julia --project=. src/column_generation.jl
```

This will run the complete Column Generation algorithm on three synthetic instances:
- **Small**: 50 flights, 6 airports
- **Medium**: 100 flights, 8 airports  
- **Large**: 150 flights, 12 airports

### Expected Output

```
Generating Data...

============================
Running instance: small
============================
No negative reduced-cost columns. Terminating.
Iterations = 4
Time Taken = 0.123
Final integer RMP cost = 25000.5
Selected pairings:
  ["F1", "F5"]
  ["F2"]
  ...
```

## Run Custom Instance

To solve your own flight schedule, modify `column_generation.jl`:

```julia
# Instead of auto-generated data, load your own
my_data = data_gen(num_flights=200, num_airports=10)
run_crew_pairing(my_data, pool_size=50)
```

## Project Structure

```
src/
├── build_network.jl       # Flight schedule data generation
├── column_generation.jl   # Main Column Generation algorithm
├── master_problem.jl      # Restricted Master Problem (RMP) solver
└── pricing_problem.jl     # Pricing Problem (shortest-path MIP)

data/                      # Place input flight schedules here
results/                   # Output solutions and metrics
```

## Algorithm Configuration

In `column_generation.jl`, adjust these parameters:

```julia
run_crew_pairing(data_instances[name], pool_size=100)
                                        ↑
                    # Number of solutions per pricing iteration
                    # Higher values = more pairings generated per iteration
                    # Typical: 20-200 depending on problem size
```

## Troubleshooting

### Gurobi License Error
```
GurobiError: Gurobi license not found
```
**Solution:** Ensure `gurobi.lic` is in your home directory, or set:
```bash
export GUROBI_HOME=/path/to/gurobi/installation
```

### OutOfMemory on Large Instances
- Reduce `pool_size` parameter
- Reduce number of flights in `data_gen()`
- Increase Gurobi's time limit in pricing problem

### Slow Convergence
- Increase `pool_size` to generate more columns per iteration
- Reduce `pool_size` if solver is spending too much time in pricing

## Performance Notes

Multi-Column Pricing dramatically accelerates convergence:

| Flights | Traditional (iter) | Multi-Column (iter) | Speedup |
|---------|------------------:|-------------------:|--------:|
| 50      | 37                | 3                  | 12x     |
| 100     | 78                | 6                  | 13x     |
| 150     | 161               | 6                  | 27x     |

## Next Steps

- Review `src/` files to understand the implementation
- Experiment with different problem sizes and parameters
- See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute improvements

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) above
2. Review [REFERENCES.md](REFERENCES.md) for academic background
3. Open a GitHub issue with details about your setup

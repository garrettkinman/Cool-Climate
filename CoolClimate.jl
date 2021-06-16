using Plots
using DataFrames
using CSV
using Flux

zipcode_data = DataFrame(CSV.File("Zip-Code-Results.csv"))
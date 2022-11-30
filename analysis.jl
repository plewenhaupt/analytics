include("ingestion_cleaning.jl")

# Load packages
using
Clustering,
Effects,
GLM,
GraphRecipes,
Graphs,
OrdinalMultinomialModels,
StatsBase,
StatsPlots

############
# ANALYSIS #
############
# Correlation matrix
col_selection = vcat([12:14, 16, 17, 19:25, 27, 29, 31, 32, 42, 44, 45, 47, 49:55, 64:67, 71, 73, 75, 79]...)
ordered_colnames = @chain names(clean_data)[col_selection] sort() 
cor_df = @chain clean_data select(col_selection)
cols = names(cor_df)
cor_types = DataFrame(cols = names(cor_df), type = eltype.(eachcol(cor_df)))
corr_matrix = @chain cor_df dropmissing() Matrix() corkendall()
max_val = maximum(abs, corr_matrix)

# So, what do I do with this correlation matrix?
#- I need p-values for all the correlations
#- Create a network from the highly correlated variables. Nodes = variables, edges = edge between nodes for variables with a strong correlation.
# Network graph
# First, remove the self-correlation
network_matrix = copy(corr_matrix)
for i=1:length(cols)
    network_matrix[i, i] = 0
end

# Remove all high correlations from the same category
category_index = [1:5, 6:8, 9:11, 12:15, 18:20, 21, 22:23, 24:25, 26:28, 29:31, 33:34]
for r in category_index
    for i = r, j = r
        network_matrix[i, j] = 0
    end
end

# Set all values below threshold to 0.0
network_matrix[findall(network_matrix .< 0.35)] .= 0.0

(n,m) = size(network_matrix)
heatmap(network_matrix, c = cgrad([:blue,:white,:red]), xticks=(1:m,ordered_colnames), xrot=90, yticks=(1:m,ordered_colnames), yflip=true, clims=(-max_val, max_val), size = (1200, 1200))
annotate!([(j, i, text(round(network_matrix[i,j],digits=2), 8,"Computer Modern",:black)) for i in 1:n for j in 1:m])


network_matrix_boolean_mask = vec(mapslices(ordered_colnames -> any(ordered_colnames .!= 0), network_matrix, dims = 1))
# Remove columns with all zeroes
network_matrix = network_matrix[:, network_matrix_boolean_mask]
# Remove rows with all zeroess
network_matrix = network_matrix[network_matrix_boolean_mask, :]

graph_names = cols[network_matrix_boolean_mask]

edge_labels = (x -> round(x, digits = 2)).(network_matrix)

graphplot(network_matrix,
            curves=false,
            nodeshape = :rect,
            names = graph_names,
            edgelabel = edge_labels,
            size = (1200, 1200))


# Linear regression
# Why would I want to do linear regression? To find out the relationship between a dependent variable and some independent variables of interest. 
# The choice of regression type is based on the dependent variable. For standard linear regression, several assumptions have to be met. 
# So, if those assumptions are not met, I need to use other types of regressions. 
# In this case, the dependent variables are ordinal, which does not meet the assumptions for standard linear regression. Instead, we are going to do an ordered probit regression. 
lm_df = @chain clean_data begin
    select(125, 127, 131, 145, 152, 153, 158, 162, 12, 13, 14, 16)
    rename(["age", "skill_area", "area", "job_level", "gender", "country", "tenure_group", "office", "engagement1", "engagement2", "engagement3", "engagement4"])
    dropmissing()
end

fm = @formula(engagement2 ~ tenure_group)

ordered_probit_model = polr(fm, lm_df, ProbitLink())

ordered_logit_model = polr(fm, lm_df, LogitLink())
deviance(ordered_probit_model)
deviance(ordered_logit_model)
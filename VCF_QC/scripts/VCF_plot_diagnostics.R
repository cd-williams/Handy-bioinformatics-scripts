# Script to generate diagnostic plots for VCFs
# We create full plots, and also plots cut off at the 90th percentile to facilitate examination of data where there are a few extremely high values that mess up the graph
library(tidyverse)
library(gridExtra)

# Parse the arguments from the command line
args <- commandArgs(trailingOnly = TRUE)

input <- args[1] # the prefix for the files with the VCF diagnostic stats
output <- args[2] # prefix for saving the plots

# Function to extract summary stats from a vector
get_summary <- function(x){
  stats <- summary(x)
  stats_text <- paste(
    "Min: ", round(stats["Min."], 3), "\n",
    "1st Q: ", round(stats["1st Qu."], 3), "\n",
    "Median: ", round(stats["Median"], 3), "\n",
    "Mean: ", round(stats["Mean"], 3), "\n",
    "3rd Q: ", round(stats["3rd Qu."], 3), "\n",
    "Max: ", round(stats["Max."], 3)
  )
}


# Site quality ---------------------------------------------------------------------------------------------------------------------
var_qual <- read_delim(paste(input, ".lqual", sep=""), delim = "\t",
           col_names = c("chr", "pos", "qual"), skip = 1)

var_qual_plot <- ggplot(var_qual, aes(qual)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
                 xlab("variant quality") +
                 annotate("text", x=min(var_qual$qual), y=0.9 * max(density(var_qual$qual)$y),
                          label = get_summary(var_qual$qual), hjust=0, vjust = 1, size = 2)

var_qual_plot_90 <- var_qual %>% filter(qual < quantile(qual, probs=0.9, na.rm=TRUE)) %>%
    ggplot(aes(qual)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
    xlab("variant quality")




# Site mean depth ---------------------------------------------------------------------------------------------------------------------
var_depth <- read_delim(paste(input, ".ldepth.mean", sep=""), delim = "\t",
           col_names = c("chr", "pos", "mean_depth", "var_depth"), skip = 1)

var_depth_plot <- ggplot(var_depth, aes(mean_depth)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                  xlab("variant depth") +
                  annotate("text", x=min(var_depth$mean_depth), y=0.9 * max(density(var_depth$mean_depth)$y),
                           label = get_summary(var_depth$mean_depth), hjust=0, vjust = 1, size = 2)

var_depth_plot_90 <- var_depth %>% filter(mean_depth < quantile(mean_depth, probs=0.9, na.rm=TRUE)) %>%
    ggplot(aes(mean_depth)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
    xlab("variant depth")



# Site missingness ---------------------------------------------------------------------------------------------------------------------
var_miss <- read_delim(paste(input, ".lmiss", sep=""), delim = "\t",
                       col_names = c("chr", "pos", "nchr", "nfiltered", "nmiss", "fmiss"), skip = 1)

var_miss_plot <- ggplot(var_miss, aes(fmiss)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                 xlab("variant missingness") +
                 annotate("text", x=min(var_miss$fmiss), y=0.9 * max(density(var_miss$fmiss)$y),
                           label = get_summary(var_miss$fmiss), hjust=0, vjust = 1, size = 2)

var_miss_plot_90 <- var_miss %>% filter(fmiss < quantile(fmiss, probs=0.9, na.rm=TRUE)) %>%
    ggplot(aes(fmiss)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
    xlab("variant missingness")


# Minor allele frequency ---------------------------------------------------------------------------------------------------------------------
var_freq <- read_delim(paste(input, ".frq", sep=""), delim = "\t",
                       col_names = c("chr", "pos", "nalleles", "nchr", "a1", "a2"), skip = 1)

var_freq$maf <- var_freq %>% select(a1, a2) %>% apply(1, function(z) min(z))

var_freq_plot <- ggplot(var_freq, aes(maf)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                 xlab("MAF") +
                 annotate("text", x=-Inf, y = Inf,
                           label = get_summary(var_freq$maf), size=2, vjust=1.2, hjust=1.2)

print(get_summary(var_freq$maf))


# Individual mean depth ---------------------------------------------------------------------------------------------------------------------
ind_depth <- read_delim(paste(input, ".idepth", sep=""), delim = "\t",
                        col_names = c("ind", "nsites", "depth"), skip = 1)

ind_depth_plot <- ggplot(ind_depth, aes(depth)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                  xlab("Individual mean depth") +
                  annotate("text", x=min(ind_depth$depth), y=0.9 * max(density(ind_depth$depth)$y),
                           label = get_summary(ind_depth$depth), hjust=0, vjust = 1, size = 2)

ind_depth_plot_90 <- ind_depth %>% filter(depth < quantile(depth, probs=0.9, na.rm=TRUE)) %>%
    ggplot(aes(depth)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
    xlab("Individual mean depth")

# Individual missingness ---------------------------------------------------------------------------------------------------------------------
ind_miss  <- read_delim(paste(input, ".imiss", sep=""), delim = "\t",
                        col_names = c("ind", "ndata", "nfiltered", "nmiss", "fmiss"), skip = 1)

ind_miss_plot <- ggplot(ind_miss, aes(fmiss)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                 xlab("Individual missingness") +
                 annotate("text", x=min(ind_miss$fmiss), y=0.9 * max(density(ind_miss$fmiss)$y),
                           label = get_summary(ind_miss$fmiss), hjust=0, vjust = 1, size = 2)


ind_miss_plot_90 <- ind_miss %>% filter(fmiss < quantile(fmiss, probs=0.9, na.rm=TRUE)) %>%
    ggplot(aes(fmiss)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
    xlab("Individual missingness") 

# Individual heterozygosity ---------------------------------------------------------------------------------------------------------------------
ind_het <- read_delim(paste(input, ".het", sep=""), delim = "\t",
           col_names = c("ind","ho", "he", "nsites", "f"), skip = 1)

ind_het_plot <- ggplot(ind_het, aes(f)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                xlab("Inbreeding coefficient") +
                annotate("text", x=min(ind_het$f), y=0.9 * max(density(ind_het$f)$y),
                           label = get_summary(ind_het$f), hjust=0, vjust = 1, size = 2)

ind_het_plot_90 <- ind_het %>% filter(f < quantile(f, probs=0.9, na.rm=TRUE)) %>%
    ggplot(aes(f)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
    xlab("Inbreeding coefficient")

# Genotype depth ---------------------------------------------------------------------------------------------------------------------
geno_depth <- read_delim(paste(input, ".gdepth", sep=""), delim = "\t")

geno_depth <- geno_depth %>% select(-c(CHROM, POS)) %>% mutate(across(everything(), as.numeric)) %>%
                             pivot_longer(cols=everything(), names_to = "VAR", values_to = "VAL") %>% drop_na()

geno_depth_plot <- ggplot(geno_depth, aes(VAL)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                   xlab("Genotype depth") +
                   annotate("text", x=min(geno_depth$VAL), y=0.9 * max(density(geno_depth$VAL)$y),
                           label = get_summary(geno_depth$VAL), hjust=0, vjust = 1, size = 2)

geno_depth_plot_90 <- geno_depth %>% filter(VAL < quantile(VAL, probs=0.9, na.rm=TRUE)) %>%
    ggplot(aes(VAL)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
    xlab("Genotype depth")

# Genotype quality ---------------------------------------------------------------------------------------------------------------------
geno_qual <- read_delim(paste(input, ".GQ.FORMAT", sep=""), delim = "\t")

geno_qual <- geno_qual %>% select(-c(CHROM, POS)) %>% mutate(across(everything(), as.numeric)) %>% 
                           pivot_longer(cols=everything(), names_to = "VAR", values_to = "VAL") %>% drop_na()

geno_qual_plot <- ggplot(geno_qual, aes(VAL)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                   xlab("Genotype quality") +
                   annotate("text", x=min(geno_qual$VAL), y=0.9 * max(density(geno_qual$VAL)$y),
                           label = get_summary(geno_qual$VAL), hjust=0, vjust = 1, size = 2)

geno_qual_plot_90 <- geno_qual %>% filter(VAL < quantile(VAL, probs=0.9, na.rm=TRUE)) %>%
    ggplot(aes(VAL)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
    xlab("Genotype quality")


# Saving the plots ---------------------------------------------------------------------------------------------------------------------
plots <- arrangeGrob(var_qual_plot, var_depth_plot, var_miss_plot, var_freq_plot, ind_depth_plot,
                     ind_miss_plot, ind_het_plot, geno_depth_plot, geno_qual_plot, nrow=5)

plots_90 <- arrangeGrob(var_qual_plot_90, var_depth_plot_90, var_miss_plot_90, ind_depth_plot_90,
                        ind_miss_plot_90, ind_het_plot_90, geno_depth_plot_90, geno_qual_plot_90, nrow=5)

ggsave(paste(output, ".png", sep=""), plots)
ggsave(paste(output, "_90.png", sep=""), plots_90)
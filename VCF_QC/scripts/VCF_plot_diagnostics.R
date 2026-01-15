# Script to generate diagnostic plots for Zchrom NGS data
library(tidyverse)
library(gridExtra)

input <- snakemake@input
output <- snakemake@output

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


# Site quality
var_qual <- read_delim(input$quality_site, delim = "\t",
           col_names = c("chr", "pos", "qual"), skip = 1)

var_qual_plot <- ggplot(var_qual, aes(qual)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() + 
                 xlab("variant quality") +
                 annotate("text", x=min(var_qual$qual), y=0.9 * max(density(var_qual$qual)$y),
                          label = get_summary(var_qual$qual), hjust=0, vjust = 1, size = 3)



# Site mean depth
var_depth <- read_delim(input$depth_site, delim = "\t",
           col_names = c("chr", "pos", "mean_depth", "var_depth"), skip = 1)

var_depth_plot <- ggplot(var_depth, aes(mean_depth)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                  xlab("variant depth") +
                  annotate("text", x=min(var_depth$mean_depth), y=0.9 * max(density(var_depth$mean_depth)$y),
                           label = get_summary(var_depth$mean_depth), hjust=0, vjust = 1, size = 3)


# Site missingness
var_miss <- read_delim(input$missing_site, delim = "\t",
                       col_names = c("chr", "pos", "nchr", "nfiltered", "nmiss", "fmiss"), skip = 1)

var_miss_plot <- ggplot(var_miss, aes(fmiss)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                 xlab("variant missingness") +
                 annotate("text", x=min(var_miss$fmiss), y=0.9 * max(density(var_miss$fmiss)$y),
                           label = get_summary(var_miss$fmiss), hjust=0, vjust = 1, size = 3)



# Minor allele frequency
var_freq <- read_delim(input$allele_freq, delim = "\t",
                       col_names = c("chr", "pos", "nalleles", "nchr", "a1", "a2"), skip = 1)

var_freq$maf <- var_freq %>% select(a1, a2) %>% apply(1, function(z) min(z))

var_freq_plot <- ggplot(var_freq, aes(maf)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                 xlab("MAF")


# Individual mean depth
ind_depth <- read_delim(input$depth_individual, delim = "\t",
                        col_names = c("ind", "nsites", "depth"), skip = 1)

ind_depth_plot <- ggplot(ind_depth, aes(depth)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                  xlab("Individual mean depth") +
                  annotate("text", x=min(ind_depth$depth), y=0.9 * max(density(ind_depth$depth)$y),
                           label = get_summary(ind_depth$depth), hjust=0, vjust = 1, size = 3)



# Individual missingness
ind_miss  <- read_delim(input$missing_individual, delim = "\t",
                        col_names = c("ind", "ndata", "nfiltered", "nmiss", "fmiss"), skip = 1)

ind_miss_plot <- ggplot(ind_miss, aes(fmiss)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                 xlab("Individual missingness") +
                 annotate("text", x=min(ind_miss$fmiss), y=0.9 * max(density(ind_miss$fmiss)$y),
                           label = get_summary(ind_miss$fmiss), hjust=0, vjust = 1, size = 3)



# Individual heterozygosity
ind_het <- read_delim(input$heterozygosity, delim = "\t",
           col_names = c("ind","ho", "he", "nsites", "f"), skip = 1)

ind_het_plot <- ggplot(ind_het, aes(f)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                xlab("Individual heterozygosity") +
                annotate("text", x=min(ind_het$f), y=0.9 * max(density(ind_het$f)$y),
                           label = get_summary(ind_het$f), hjust=0, vjust = 1, size = 3)

individual_plots <- arrangeGrob(ind_depth_plot, ind_miss_plot, ind_het_plot, nrow=3)

# Genotype depth
geno_depth <- read_delim(input$depth_genotype, delim = "\t")

geno_depth <- geno_depth %>% select(-c(CHROM, POS)) %>% mutate(across(everything(), as.numeric)) %>%
                             pivot_longer(cols=everything(), names_to = "VAR", values_to = "VAL") %>% drop_na()

geno_depth_plot <- ggplot(geno_depth, aes(VAL)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                   xlab("Genotype depth") +
                   annotate("text", x=min(geno_depth$VAL), y=0.9 * max(density(geno_depth$VAL)$y),
                           label = get_summary(geno_depth$VAL), hjust=0, vjust = 1, size = 3)

# Genotype quality
geno_qual <- read_delim(input$quality_genotype, delim = "\t")

geno_qual <- geno_qual %>% select(-c(CHROM, POS)) %>% mutate(across(everything(), as.numeric)) %>% 
                           pivot_longer(cols=everything(), names_to = "VAR", values_to = "VAL") %>% drop_na()

geno_qual_plot <- ggplot(geno_qual, aes(VAL)) + geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) + theme_light() +
                   xlab("Genotype quality") +
                   annotate("text", x=min(geno_qual$VAL), y=0.9 * max(density(geno_qual$VAL)$y),
                           label = get_summary(geno_qual$VAL), hjust=0, vjust = 1, size = 3)

plots <- arrangeGrob(var_qual_plot, var_depth_plot, var_miss_plot, var_freq_plot, ind_depth_plot,
                     ind_miss_plot, ind_het_plot, geno_depth_plot, geno_qual_plot, nrow=5)

ggsave(output$plots, plots)

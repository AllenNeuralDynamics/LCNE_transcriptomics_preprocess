# this is edited and added the saving steps.. 
filepath <- '/allen/programs/celltypes/workgroups/rnaseqanalysis/SMARTer/STAR/Mouse/facs/R_Object/SparseMatrix/'

filelist = list.files(filepath, pattern="250206")
metafile = filelist[grep('samp.dat',filelist)]
load(paste0(filepath, metafile))

kept_samples = which(samp.dat$studies=="Neuromodulatory_Noradrenergic")



exonfile = filelist[grep('exon',filelist)]
intronfile = filelist[grep('intron',filelist)]
cat(exonfile,intronfile)


my_retroseq_data_csv <- data.frame(
  ID = c(720570, 720571, 729424, 731339, 734350, 734351, 736527, 736528, 744523, 744524, 744526, 745034, 754294, 754295, 755030, 758591, 758586, 758590, 759651, 759654),
  Date = c("4/16/24", "4/16/24", "7/1/24", "7/1/24", "7/1/24", "7/1/24", "8/29/24", "8/29/24", "8/29/24", "8/29/24", "8/29/24", "8/29/24", "11/22/24", "11/22/24", "11/22/24", "11/22/24", "11/27/24", "11/27/24", "11/27/24", "11/27/24"),
  Version = rep("SSv4", 20),
  injection_target = c("frontal cortex", "cerebellum", "frontal cortex", "cerebellum", "spinal cord", "spinal cord", "cerebellum", "frontal cortex", "spinal cord", "spinal cord", "spinal cord", "spinal cord", "spinal cord", "spinal cord", "thalamus", "spinal cord", "thalamus", "thalamus", "thalamus", "thalamus"),
  Reference = c("RSC-363", "RSC-363", "RSC-370", "RSC-370", "sort_fail", "RSC-370", "RSC-376", "RSC-376", "sort_fail", "RSC-377", "RSC-377", "RSC-377", "RSC-380", "RSC-380", "RSC-380", "RSC-380", "RSC-380", "RSC-380", "RSC-381", "RSC-381")
)
# Print the data frame you created
print(my_retroseq_data_csv)
matching_rows <- samp.dat[samp.dat$external_donor_name %in% my_retroseq_data_csv$ID, ] # should be 760 131
my_retroseq_data_csv$ID <- as.character(my_retroseq_data_csv$ID)
matching_rows$external_donor_name <- as.character(matching_rows$external_donor_name)
dim(matching_rows) #1383  131

library(dplyr)
final_matching_rows <- matching_rows %>%  # this gives 1383 
  left_join(
    my_retroseq_data_csv %>% rename(ID_in_csv = ID), # Rename to avoid conflicts
    by = c("external_donor_name" = "ID_in_csv")
  )

matching_colnames <- final_matching_rows$exp_component_name # this is 1383
length(matching_colnames)


### now load introns exons and then subset
### 1. introrn
load(paste0(filepath, intronfile))
allcellnames = colnames(intron) 
dim(intron) # 32245 187518
intron = t(intron)[which(allcellnames %in% matching_colnames),]
dim(intron) # 1383 187518

### 2. exon
load(paste0(filepath, exonfile)) # dim(exon) is 32245 185332
allcellnames = colnames(exon) 
dim(exon) # 32245 187518
exon = t(exon)[which(allcellnames %in% matching_colnames),]
dim(exon) # 1383 187518




# now put them together 
allcounts = exon+intron
max(allcounts)  # 59784







# some saving options (copied from snRNA case)
saveloc = '~/scratch_shuonan/retroseqdata/raw_from_R/'


# metadata
savedfilename = paste0(saveloc, 'metadata.csv')
samp.dat_sub = samp.dat[which(samp.dat$exp_component_name %in% matching_colnames),]
write.csv(samp.dat_sub, savedfilename, row.names = TRUE)


## all counrs (intron+exons)
mat <- as(as.matrix(allcounts), "dgCMatrix")
savedfilename = paste0(saveloc, 'retro_raw.mtx')
writeMM(mat, savedfilename)
write.table(colnames(allcounts), file = paste0(saveloc, 'genes.tsv'),
            quote = FALSE, row.names = FALSE, col.names = FALSE)
write.table(rownames(allcounts), file = paste0(saveloc, 'cells.tsv'),
            quote = FALSE, row.names = FALSE, col.names = FALSE)



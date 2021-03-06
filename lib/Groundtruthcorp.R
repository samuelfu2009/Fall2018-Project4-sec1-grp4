
################################# Pre Processing ###################################


file_name_vec <- list.files("~/Desktop/5243/Fall2018-Project4-sec1--sec1-proj4-grp4/data/ground_truth")
library(openxlsx)
missingline<- read.xlsx('~/Desktop/5243/Fall2018-Project4-sec1--sec1-proj4-grp4/data/AddLine_ver2.xlsx')
#missingline$FileName

truth_all<- c()
tess_all<- c()
for(i in c(1:length(file_name_vec))){
  truth<- readLines(paste0('~/Desktop/5243/Fall2018-Project4-sec1--sec1-proj4-grp4/data/ground_truth/',file_name_vec[i]))
  tess<- readLines(paste0('~/Desktop/5243/Fall2018-Project4-sec1--sec1-proj4-grp4/data/tesseract/',file_name_vec[i]))
  for (j in missingline$FileName) {
    if(file_name_vec[i]==j){
      addline<- as.numeric(missingline[which(missingline$FileName==j),"Line"])
      if(addline>length(tess)){
        tess<- c(tess,' ')
      }
      else{
        tess<- c(tess[1:(addline-1)],' ',tess[addline:length(tess)])
      }
    }
  }
  truth_all<- c(truth_all,truth)
  tess_all<- c(tess_all,tess)
  #print(file_name_vec[i])
  #print(length(truth)==length(tess))
  #write.table(tess,file = file_name_vec[i])
}

length(truth_all)
length(tess_all)

#error<- readLines('D:/ADS_Proj4_Grp4/data/tesseract/group1_00000005.txt')
#truth<- readLines('D:/ADS_Proj4_Grp4/data/ground_truth/group1_00000005.txt')
#txt<- writeLines(error,sep = "\n")
#num<- 0
#for(i in error){
#  splitted<- strsplit(i,' ')
#  splitted<- splitted[[1]]
#  num<- num+length(splitted)
#}
#print(num)



###################################### Keep lins with same number of tokens  ##########################################

library(tokenizers)
#char_vector_gt <- readLines("D:/ADS_Proj4_Grp4/data/ground_truth/group1_00000049.txt")
#gt_token<- tokenize_words(char_vector_gt)
#char_vector_tr <- readLines("D:/ADS_Proj4_Grp4/data/tesseract/group1_00000049.txt")
#tr_token<- tokenize_words(char_vector_tr)
#gt_token <- tokenize_words(truth_all)
gt_token2<- strsplit(truth_all,' ')
#tr_token <- tokenize_words(tess_all)
tr_token2<- strsplit(tess_all,' ')

#i <- 0
#k <- 0
#gt_right_token <- list()
#tr_right_token <- list()
#for (n in 1:length(gt_token2)){
#  if (length(gt_token2[[n]]) == length(tr_token2[[n]])) {
#    
#    i = i + 1
#    gt_right_token[[i]] <- sapply(gt_token2[[n]],tolower)
#    tr_right_token[[i]] <- sapply(tr_token2[[n]],tolower)
#  } else{
#    k = k+1
#  }
#}
#print(i)
#print(k)

i <- 0
k <- 0
gt_right_token <- list()
tr_right_token <- list()
for (n in 1:length(gt_token2)){
  if (length(gt_token2[[n]]) == length(tr_token2[[n]])) {
    
    i = i + 1
    gt_right_token[[i]] <- sapply(sapply(gt_token2[[n]], tolower),removePunctuation)
    tr_right_token[[i]] <- sapply(sapply(tr_token2[[n]], tolower),removePunctuation)
  } else{
    k = k+1
  }
}
print(i)
print(k)


############################# Combined groundtruth and tess words ######################################

row_ = list()
col_ = list()
char_ = list()
char_tr = list()
error = list()
i <- 1
for ( per_row in 1:length(gt_right_token)) {
  for (per_col in 1:length(gt_right_token[[per_row]])) {
    row_[i] <- per_row
    col_[i] <- per_col
    char_[i] <- gt_right_token[[per_row]][per_col]
    char_tr[i] <- tr_right_token[[per_row]][per_col]
    error[i] <- ifelse(gt_right_token[[per_row]][per_col] == tr_right_token[[per_row]][per_col], 0, 1)
    i = i +1
    
  }
}

data_frame_gt_row <- as.data.frame(as.vector(unlist(row_)))
data_frame_gt_col <- as.data.frame(as.vector(unlist(col_)))
data_frame_gt_char <- as.data.frame(as.vector(unlist(char_)))
data_frame_tr_char <- as.data.frame(as.vector(unlist(char_tr)))
data_frame_error <- as.data.frame(as.vector(unlist(error)))
data_frame <- cbind(data_frame_gt_row,data_frame_gt_col,data_frame_gt_char,data_frame_tr_char,data_frame_error )
names(data_frame) <- c("row","col","character_gt","character_tr","error")

dim(data_frame)
dim(data_frame[which(data_frame['error']==1),])

dict_word <- data_frame["character_gt"]
dim(unique(dict_word))


############ groundtruth corpus ##############
library(tm)
library(dplyr)
library(tidytext)
library('hash')


dict <- data_frame_gt_char
colnames(dict) <- 'words' # create data frame for dictionary, and colname is 'words'


### For words
corp_groundtruth <- dict %>% 
  count(words, sort =T) 
head(corp_groundtruth, 20) # the frequency of the words
library('hash')
corplist_word_groundtruth<- hash(keys=corp_groundtruth$words,values=corp_groundtruth$n)
N_groundtruth<- sum(corp_groundtruth$n)
V_groundtruth<-length(corp_groundtruth$words)

### For single and bigram
strcount <- function(x, pattern){
  unlist(lapply(strsplit(x, NULL),function(z) na.omit(length(grep(pattern, z)))))
}

search_for_bi<- function(bi){
  total<- 0
  for(i in corp_groundtruth$words){
    num<- sum(gregexpr(bi, i, fixed=TRUE)[[1]] > 0)
    total<- total+num
  }
  return(total)
}

bi_mat<- matrix(0,26,26)
colnames(bi_mat)<- letters
rownames(bi_mat)<- letters

corp_char<- matrix(NA,nrow=1,ncol=702)
cc<- c()
for(i in letters){
  for(j in letters){
    cc<- c(cc,paste0(i,j))
  }
}
colnames(corp_char)<- c(letters,cc)
for(i in letters){
  for(j in letters){
    bi<- paste0(i,j)
    num<- search_for_bi(bi)
    corp_char[1,bi]<- num
  }
}

for (i in letters) {
  total<- 0
  for(j in corp_groundtruth$words){
    num<- sum(gregexpr(i, j, fixed=TRUE)[[1]] > 0)
    total<- total+num
  }
  corp_char[1,i]<- total
}

corplist_char_groundtruth<- hash(keys=colnames(corp_char),values=corp_char[1,])

### Save Corpus
save(corp_groundtruth,N_groundtruth,V_groundtruth,corplist_word_groundtruth,corplist_char_groundtruth,file = 'Groundtruth_corpus.RData')



################# Reversion Confusion Matrice ################
rev_mat<- matrix(0,26,26)
colnames(rev_mat)<- letters
rownames(rev_mat)<- letters

wrongtext<- data_frame[data_frame$error==1,]
for (i in 1:nrow(wrongtext)) {  
  tr<- as.character(wrongtext$character_tr[i])
  gt<- as.character(wrongtext$character_gt[i])
  char_list<- unlist(strsplit(tr,NULL))
  #print(char_list)
  #print(char_list)
  if(length(char_list)>=2){
    for (j in 1:(length(char_list)-1)) {
      temp_char_list<- char_list
      y<- char_list[j]
      x<- char_list[j+1]
      temp_char_list[j]<- x
      temp_char_list[j+1]<- y
      temp_char<- paste(temp_char_list,collapse = "")
      print(temp_char)    
      if(temp_char==gt){
        rev_mat[x,y]<- rev_mat[x,y]+1
      }
    }
  }
}


################### Substitution Confusion Matrice ###################
sub_mat<- matrix(0,26,26)
colnames(sub_mat)<- letters
rownames(sub_mat)<- letters

for (i in 1:nrow(wrongtext)) {  
  tr<- as.character(wrongtext$character_tr[i])
  gt<- as.character(wrongtext$character_gt[i])
  char_list<- unlist(strsplit(tr,NULL))
  for(j in 1:length(char_list)){
    x<- char_list[j]
    temp_char_list<- char_list
    for (y in letters) {
      temp_char_list[j]<- y
      temp_char<- paste(temp_char_list,collapse = "")
      if(temp_char==gt && (x %in% letters) && (y %in% letters)){
        cat(x,y,sep = '/')
        sub_mat[x,y]<- sub_mat[x,y]+1
      }
    }
  }
}

save(rev_mat,sub_mat,file='ConfusionMatrice_groundtruth.RData')
load('ConfusionMatrice_groundtruth.RData')

############################### Generate candidates & Compute Confusion Matrix ######################################


wrong_data <- data_frame[which(data_frame['error']==1),]
dim(wrong_data)[1]

### Deletion confusion matrix

# Generate empty matrix
del_matrix <- matrix(0, nrow = 27, ncol = 26, dimnames = list(c(letters[1:26],"@"),c(letters[1:26])))
# Write calculation function
del_candidate <- function(wrong_word,right_word){
  for (n in 0:nchar(wrong_word)){
    if (n == 0){
      x <- "@"
      for (y in letters[1:26]){
        if (paste0(y,wrong_word) == right_word){del_matrix[x,y] = del_matrix[x,y] + 1}
      }
    } else{
      if (substr(wrong_word,n,n) %in% letters){
        x <- substr(wrong_word,n,n)
        for (y in letters[1:26]){ 
          if (paste0(substr(wrong_word,1,n),y,substr(wrong_word,n+1,nchar(wrong_word))) == right_word){del_matrix[x,y] = del_matrix[x,y] + 1}
        }
      }
    }
  }
  return(del_matrix)
}
# Check for each pair of words
for (num in 1:dim(wrong_data)[1]){
  wrong_word <- as.character(wrong_data$character_tr[num])
  right_word <- as.character(wrong_data$character_gt[num])
  del_matrix <- del_candidate(wrong_word,right_word)
  if (num%%1000 == 0){print("1000")}
}
# Save the matrix as R data
#save(del_matrix, file = "del_matrix_groundtruth.RData") # load("del_matrix_groundtruth.RData")


### Insertion confusion matrix

# Generate empty matrix
insert_matrix <- matrix(0, nrow = 27, ncol = 26, dimnames = list(c(letters[1:26],"@"),c(letters[1:26])))
# Write calculation function
insert_candidate <- function(wrong_word,right_word){
  for (n in 0:nchar(wrong_word)-1){
    if (n == 0 & substr(wrong_word,n+1,n+1) %in% letters){
      x <- "@"
      if (substr(wrong_word,2,nchar(wrong_word)) == right_word){
        y <- substr(wrong_word,1,1)
        insert_matrix[x,y] = insert_matrix[x,y] + 1
        #print(wrong_word)
        #print(right_word)
      }
    } else{
      if (substr(wrong_word,n,n) %in% letters & substr(wrong_word,n+1,n+1) %in% letters){
        x <- substr(wrong_word,n,n)
        if (paste0(substr(wrong_word,1,n),substr(wrong_word,n+2,nchar(wrong_word))) == right_word){
          y <- substr(wrong_word,n+1,n+1)
          insert_matrix[x,y] = insert_matrix[x,y] + 1
          #print(wrong_word)
          #print(right_word)
        }
      }
    }
  }
  return(insert_matrix)
}
# Check for each pair of words
for (num in 1:dim(wrong_data)[1]){
  wrong_word <- as.character(wrong_data$character_tr[num])
  right_word <- as.character(wrong_data$character_gt[num])
  insert_matrix <- insert_candidate(wrong_word,right_word)
  if (num%%1000 == 0){print("1000")}
}
# Save the matrix as R data
# save(insert_matrix, file = "insert_matrix_groundtruth.RData") 
# load("insert_matrix_groundtruth.RData")

save(rev_mat,sub_mat,del_matrix,insert_matrix,file='ConfusionMatrice_groundtruth.RData')
load('ConfusionMatrice_groundtruth.RData')

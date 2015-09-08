#!/bin/bash 
echo "**************************"
echo "      aims2vasp           "
echo "                          "
echo " Written by M.R.Farrow    "
echo "    V1.0   Oct 2014       " 
echo "**************************"

if [ -f POSCAR.vasp ] ;then
   echo "POSCAR.vasp already exists, moving to POSCAR.vasp.old"
   mv POSCAR.vasp POSCAR.vasp.old
fi

#  First create the header
echo "# POSCAR created from aim2vasp from FHI-aims system" > POSCAR.vasp
echo "1.0000000" >> POSCAR.vasp
# Are we converting a FHI-aims geometry file? 
if [ $1 == geometry.in ] || [ $1 == geometry.in.nextstep ]; then
   echo "FHI-aims geometry.in file being converted"
   cell=`grep lattice_vector $1 | wc -l`
   if [ $cell > 0 ]; then
      echo "Bulk system detected" 
      grep lattice_vector $1 | awk '{print $2,$3,$4}' >> POSCAR.vasp
   else
      echo "50.000 0.0000 0.0000" >> POSCAR.vasp
      echo "0.000 50.000 0.0000" >> POSCAR.vasp
      echo "0.000 0.0000 50.000" >> POSCAR.vasp
   fi
# Now to sort out the atom types and numbers   
   num_types=1
   counter=`grep atom $1 | wc -l`
   echo $counter atoms detected
   type_1=`grep atom $1 | head -1 | awk '{print $5}'`
   echo Found $type_1 atom
   type_array[0]=`echo $type_1`
   for ((i=1 ; i <= $counter ; i++ ))
   do
     type_tmp=`grep atom $1 | awk '{print $5}'`
     type_2=`echo $type_tmp | awk -v val=$i '{print $val}'`
     match_flg=0
     for j in "${type_array[@]}" 
     do
       if [ $type_2 == $j ]; then
          match_flg=1
       fi
     done 
     if [ "$match_flg" == 0 ]; then 
        num_types=$((num_types + 1))
        type_array[$num_types]=`echo $type_2`
        echo New atom type found, $type_2
        echo $num_types types found so far
     fi
     done
# Contine with POSCAR creation
    echo ${type_array[@]} >> POSCAR.vasp 
    k=0
    for i in "${type_array[@]}"
    do 
    val[k]=`grep $i $1 | grep -c atom`
    k=$((k+1))
    done
    echo ${val[@]} >> POSCAR.vasp 
# Direct or Cartesian?     
    counter=`grep "atom_frac" $1 | wc -l`
    if [ "$counter" -gt 0 ]; then 
       #Fractionals detected!
       echo Found fractional coordinates
       echo Direct >> POSCAR.vasp
    else
       #Must be cartesian coords
       echo Cartesian >> POSCAR.vasp
    fi

    for i in "${type_array[@]}"
    do
      echo $i
      grep $i $1 | grep "atom" | awk '{printf("%f %f %f \n", $2,$3,$4)}' >> POSCAR.vasp
    done
#  if not, assumed to be FHI-aims output file
else
   echo "Assuming FHI-aims output file being converted"
   cell=`grep lattice_vector $1 | tail -3 | wc -l`
   if [ $cell > 0 ]; then
      echo "Bulk system detected" 
      grep lattice_vector $1 | tail -3 | awk '{print $2,$3,$4}' >> POSCAR.vasp
   else
      echo "50.000 0.0000 0.0000" >> POSCAR.vasp
      echo "0.000 50.000 0.0000" >> POSCAR.vasp
      echo "0.000 0.0000 50.000" >> POSCAR.vasp
    fi
# Now to sort out the atom types and numbers   
   num_types=1
   counter=`grep "Number of atoms " $1 | awk '{print $6}'` 
   echo $counter atoms detected
   type_1=`grep Species: $1 | head -1 | awk '{print $2}'`
   type_array[0]=`echo $type_1`
   type_tmp=`grep Species: $1 | awk '{print $2}'`
   num_types=`grep "Number of species " $1 | awk '{print $6}'`
   echo There are $num_types types of atoms
# Update POSCAR 
   echo ${type_tmp[@]} >> POSCAR.vasp
   k=0
   for (( i = 1 ; i <= $num_types ; i++ )) 
   do 
     type_array[$i]=`echo ${type_tmp[@]} | awk -v val=$i '{print $val}'` 
     echo Found ${type_array[$i]} atom
     val[k]=`grep "Species ${type_array[$i]}    " $1  | grep "|" | wc -l`
     k=$((k+1))
   done
   echo ${val[@]} >> POSCAR.vasp
# Now to add the positions
# Direct or Cartesian?     
    counter=`grep "atom_frac" $1 | wc -l`
    if [ $counter > 0 ]; then 
       #Fractionals detected!
       echo Direct >> POSCAR.vasp
    else
       #Must be cartesian coords
       echo Cartesian >> POSCAR.vasp
    fi
    k=0
    for (( i = 1 ; i <= $num_types ; i++ ))
    do
    num=$((0 - ${val[k]} ))
    grep ${type_array[$i]} $1 | grep atom | awk '{printf("%f %f %f \n", $2,$3,$4)}' | tail $num >> POSCAR.vasp 
    k=$((k+1))
    done
fi
  echo New file POSCAR.vasp created.

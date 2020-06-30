# Not-so-simple-ALU

The state machine has the following states: reset, header, payload, adresare, operatii, amm, header_out, payload_out, header_notok, payload_notok.

The "reset" state resets 2 counting variables: contor_next and rez_next. Contor_next counts the number of operands and later on is used to acces the content of each operand in the "operatii" state. Rez_next contains the result of the future state.

The "header" state decodes data_in (the data that is received) and founds out the opcode (operation code) and nof_opcode (number of operands). There are certain conditions for the reading of the header.


2. header
In aceasta stare se decodeaza data_in, astfel afland opcode si nof_operands. Nu se iese
din aceasta stare, decat daca au fost indeplinitie conditiile de citire ale headerului.
3. payload
In aceasta stare, citesc pe rand toti operanzii. Contorul merge pana la nof_operans-1
deoarece am pornit cu contorul de la 0. Ulterior, trece in starea de adresare, sau daca conditiile de payload (valid, cmd) nu sunt indeplinite, intr-o stare ce va genera
eroarea.
4. adresare
In aceasta stare se selecteaza cazul corespunzator, in functie de modul de adresare: daca operand_or_address contine operandul va trece la starea de operatii, altfel
va trece la starea amm.
5. operatii
In aceasta stare se executa operatiile, atat pentru operanzii ce sunt direct in operand_or_address, cat si cei ce trebuiesc adusi din memorie. Fiecare instructiune are un cod specific, in functie de care vom face o anumita operatie. Operatiile au fost explicate la laborator.
Page 1
README
6. amm
In aceasta stare incepe lucrul cu memoria. Pentru a lua o adresa de memorie am asteptat
3 cicluri de ceas (de aceea se trece dintr-o stare in alta). In final, din memorie obtinem operandul in operandor address, pe care il vom duce ulterior in starea de operatii.
7. header_out
In aceasta stare se indeplinesc conditiile de livrare ale headerului si se transmite.
8. payload_out
In aceasta stare se indeplinesc conditiile de payload si se trimite.
Starile header_notok si paylaod_notok sunt pentru a genera direct codul de erori.

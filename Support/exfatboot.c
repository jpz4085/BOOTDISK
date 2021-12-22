//  main.c
//  exfatboot - Write new exFAT bootstrapping code from file.
//
//  Created by Joseph P. Zeller on 12/20/19.
//  Copyright © 2019 Joseph P. Zeller. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/disk.h>

int usage(void);
int help(void);
int disk_error(const char* disk);
uint32_t exfat_boot_checksum(const void* sector, size_t size);

int main(int argc, const char * argv[]) {
    
    FILE *bootcode, *partition;
    unsigned char *bcbuffer, *vbrbuffer, *csbuffer, csbytes[4];
    unsigned int bcsize, vbrmain, vbrbackup, csmain, csbackup;
    uint32_t sector_size, newchecksum, oldchecksum;

    // Check for proper command usage then open bootcode file and/or disk partition.
    if (!argv[1]) { usage(); }
    if (argc > 4) { usage(); }
    if (strcmp(argv[1], "-h") == 0) { help(); }
    if (strcmp(argv[1], "-B") == 0) {
        if (!argv[2]) { usage(); }
        if (strstr(argv[2], "dev/disk") != NULL) { usage(); }
        bootcode = fopen(argv[2], "rb");
        if (!bootcode) {
            fprintf(stderr, "Error: can't access %s \n", argv[2]);
            exit(1);
        }
        if (!argv[3] || strstr(argv[3], "dev/disk") == NULL) {
            fclose(bootcode);
            usage();
        }
        partition = fopen(argv[3], "wb+");
        if (!partition) {
            fclose(bootcode);
            disk_error(argv[3]);
        }
        // Write bootstrapping code to VBR of selected partition.
        fseek(bootcode, 0, SEEK_END);
        bcsize = (unsigned int) (ftell(bootcode) - 120);
        bcbuffer = malloc(bcsize);
        if (!bcbuffer) {
            fprintf(stderr, "Error: can't allocate memory to write boot code.\n");
            fclose(bootcode);
            exit(1);
        }
        fseek(bootcode, 120, SEEK_SET);
        fread(bcbuffer, bcsize, 1, bootcode);
        fseek(partition, 120, SEEK_SET);
        vbrmain = (unsigned int) fwrite(bcbuffer, bcsize, 1, partition);
        if (vbrmain < 1) {
            printf("Failed to update main boot region code.\n");
            fclose(bootcode);
            fclose(partition);
            free(bcbuffer);
            exit(1);
        }
        fseek(partition, (6264 - (bcsize + 120)), SEEK_CUR);
        vbrbackup = (unsigned int) fwrite(bcbuffer, bcsize, 1, partition);
        if (vbrbackup < 1) {
            printf("Failed to update backup boot region code.\n");
            fclose(bootcode);
            fclose(partition);
            free(bcbuffer);
            exit(1);
        }
        fclose(bootcode);
        free(bcbuffer);
        if (vbrmain == 1 && vbrbackup == 1) {
            printf("Boot sector code updated sucessfully.\n");
        }
    }
    else {
        if (strstr(argv[1], "dev/disk") == NULL) { usage(); }
        partition = fopen(argv[1], "wb+");
        if (!partition) { disk_error(argv[1]); }
    }
    // Recalculate and verifiy current VBR checksum.
    sector_size = 0;
    int iFd = fileno(partition);
    int iRes1 = ioctl(iFd, DKIOCGETBLOCKSIZE, &sector_size);
    if (iRes1) {
        sector_size = 512;
    }
    vbrbuffer = malloc(sector_size * 11);
    if (!vbrbuffer) {
        fprintf(stderr, "Error: can't allocate memory to read sector data.\n");
        fclose(partition);
        exit(1);
    }
    fseek(partition, 0, SEEK_SET);
    fread(vbrbuffer, sector_size, 11, partition);
    newchecksum = exfat_boot_checksum(vbrbuffer, sector_size);
    fread(csbytes, 4, 1, partition);
    oldchecksum = (uint32_t)csbytes[3] << 24 |
                  (uint32_t)csbytes[2] << 16 |
                  (uint32_t)csbytes[1] << 8  |
                  (uint32_t)csbytes[0];
    
    if (newchecksum == oldchecksum){
        printf("Checksum is valid. No update performed.\n");
        free(vbrbuffer);
    }
    // Write new VBR checksum if current is invalid.
    else {
        csbuffer = realloc(vbrbuffer, sector_size);
        if (!csbuffer) {
            fprintf(stderr, "Error: can't allocate memory for checksum sector.\n");
            fclose(partition);
            free(vbrbuffer);
            exit(1);
        }
        memset_pattern4(csbuffer, &newchecksum , sector_size);
        fseek(partition, sector_size * 11, SEEK_SET);
        csmain = (unsigned int) fwrite(csbuffer, sector_size, 1, partition);
        if (csmain < 1) {
            printf("Failed to update main checksum sector.\n");
            fclose(partition);
            free(csbuffer);
            exit(1);
        }
        fseek(partition, sector_size * 23, SEEK_SET);
        csbackup = (unsigned int) fwrite(csbuffer, sector_size, 1, partition);
        if (csbackup < 1) {
            printf("Failed to update backup checksum sector.\n");
            fclose(partition);
            free(csbuffer);
            exit(1);
        }
        free(csbuffer);
        if (csmain == 1 && csbackup == 1) {
            printf("Checksum sectors updated successfully.\n");
        }
    }
    fclose(partition);
    return 0;
}

int usage(void)
{
    printf("usage: exfatboot [-h help] [-B bootfile] /dev/disk#s#\n");
    exit(0);
}

int help(void)
{
    printf("exFAT Bootcode Tool\n");
    printf("\n");
    printf("Utility to write bootstrap code to exFAT volume boot regions.\n");
    printf("Root permission required to access disk such as: /dev/disk2s1.\n");
    printf("Run without options to check and update existing VBR checksum.\n");
    printf("\n");
    printf("Usage: exfatboot [options] /dev/disk#s#\n");
    printf("        -h: print this help screen\n");
    printf("        -B: specify a boot sector file\n");
    printf("\n");
    exit(0);
}

int disk_error(const char* disk)
{
    fprintf(stderr, "Error: can't access disk %s \n", disk);
    printf("Root permission (sudo) required.\n");
    exit(1);
}

uint32_t exfat_boot_checksum(const void* sector, size_t size)
{
    size_t i;
    uint32_t sum = 0;
    uint32_t block = (uint32_t)size * 11;
    
    for (i = 0; i < block; i++)
    /* skip volume_state and allocated_percent fields */
        if (i != 0x6a && i != 0x6b && i != 0x70)
            sum = ((sum << 31) | (sum >> 1)) + ((const uint8_t*) sector)[i];
    return sum;
}

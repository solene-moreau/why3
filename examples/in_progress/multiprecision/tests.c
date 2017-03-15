#include <gmp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

uint64_t add(uint64_t * r3, uint64_t * x4, uint64_t * y3, int32_t sx, int32_t
             sy);

void mul(uint64_t * r10, uint64_t * x11, uint64_t * y10, int32_t sx2, int32_t
         sy2);

void div_qr(uint64_t * q, uint64_t * r, uint64_t * x, uint64_t * y,
            uint64_t * nx, uint64_t * ny,  int32_t sx, int32_t sy);

#define TMP_ALLOC_LIMBS(n) malloc((n) * 8)

void mpn_dump(mp_ptr ap, mp_size_t an) {
  for (mp_size_t i = 0; i != an; ++i)
    printf("%016lx ", ap[i]);
  printf("\n");
}

#if defined(TEST_GMP) || defined(TEST_WHY3)
#define BENCH
#else
#define COMPARE
#define TEST_GMP
#define TEST_WHY3
#endif

int main () {
  mp_ptr ap, bp, rp, refp, rq, rr, refq, refr;
  mp_size_t max_n, an, bn, rn;
  struct timeval begin, end;
  double elapsed;
  //gmp_randstate_t rands;
  //TMP_DECL;
  //TMP_MARK;

  //tests_start ();
  //TESTS_REPS (reps, argv, argc);

  //gmp_randinit_default(rands);
  //gmp_randseed_ui(rands, 42);

  /* Re-interpret reps argument as a size argument.  */
  max_n = 20;

  ap = TMP_ALLOC_LIMBS (max_n + 1);
  bp = TMP_ALLOC_LIMBS (max_n + 1);
  /* nap = TMP_ALLOC_LIMBS (max_n + 1); */
  /* nbp = TMP_ALLOC_LIMBS (max_n + 1); */
  rp = TMP_ALLOC_LIMBS (2 * max_n);
  refp = TMP_ALLOC_LIMBS (2 * max_n);
  rq = TMP_ALLOC_LIMBS (max_n + 1);
  rr = TMP_ALLOC_LIMBS (max_n + 1);
  refq = TMP_ALLOC_LIMBS (max_n + 1);
  refr = TMP_ALLOC_LIMBS (max_n + 1);

  for (an = 2; an <= max_n; an += 1)
    {
      for (bn = 1; bn <= an; bn += 1)
	{
	  mpn_random2 (ap, an + 1);
	  mpn_random2 (bp, bn + 1);

          while (bp[bn-1] == 0)
            {
              //printf("an = %d, bn = %d, aborted\n", (int)an, (int)bn);
              mpn_random2 (bp, bn + 1);
            };

#ifdef BENCH

          gettimeofday(&begin, NULL);
          for (int iter = 0; iter != 10000; ++iter) {
#endif

#ifdef TEST_GMP
            mpn_mul (refp, ap, an, bp, bn);
#endif
#ifdef TEST_WHY3
            mul (rp, ap, bp, an, bn);
#endif

#ifdef BENCH
          }
          gettimeofday(&end, NULL);
          elapsed =
            (end.tv_sec - begin.tv_sec)
            + ((end.tv_usec - begin.tv_usec)/1000000.0);
          printf ("multiplication: an=%d, bn=%d, t=%f\n", (int)an, (int)bn, elapsed);
#endif
#ifdef COMPARE
	  rn = an + bn;
	  if (mpn_cmp (refp, rp, rn))
	    {
	      printf ("ERROR, an = %d, bn = %d, rn = %d\n",
		      (int) an, (int) bn, (int) rn);
	      printf ("a: "); mpn_dump (ap, an);
	      printf ("b: "); mpn_dump (bp, bn);
	      printf ("r:   "); mpn_dump (rp, rn);
	      printf ("ref: "); mpn_dump (refp, rn);
	      abort();
	    }
#endif
        }
    }
  for (an = 2; an <= max_n; an += 1)
    {
      for (bn = 1; bn <= an; bn += 1)
        {
          mpn_random2 (ap, an + 1);
	  mpn_random2 (bp, bn + 1);

          while (bp[bn-1] == 0)
            {
              //printf("an = %d, bn = %d, aborted\n", (int)an, (int)bn);
              mpn_random2 (bp, bn + 1);
            };
#ifdef BENCH
          gettimeofday(&begin, NULL);
          for (int iter = 0; iter != 100000; ++iter) {
#endif

#ifdef TEST_GMP
            mpn_tdiv_qr (refq, refr, 0, ap, an, bp, bn);
#endif
#ifdef TEST_WHY3
            tdiv_qr(rq, rr, ap, bp, an, bn);
#endif

#ifdef BENCH
        }
          gettimeofday(&end, NULL);
          elapsed =
            (end.tv_sec - begin.tv_sec)
            + ((end.tv_usec - begin.tv_usec)/1000000.0);
          printf ("division: an=%d, bn=%d, t=%f\n"
//, am=%016lx\n

                  , (int)an, (int)bn, elapsed
                  // , ap[an]
                  );
#endif
#ifdef COMPARE
          rn = bn;
          if (mpn_cmp (refr, rr, rn))
	    {
	      printf ("ERROR, an = %d, bn = %d, rn = %d\n",
		      (int) an, (int) bn, (int) rn);
	      printf ("a: "); mpn_dump (ap, an);
	      printf ("b: "); mpn_dump (bp, bn);
	      printf ("q:    "); mpn_dump (rq, an-bn+2);
	      printf ("refq: "); mpn_dump (refq, an-bn+2);
	      printf ("r:    "); mpn_dump (rr, rn);
	      printf ("refr: "); mpn_dump (refr, rn);
	      abort();
	    }
          rn = an - bn + 1;
          if (mpn_cmp (refq, rq, rn))
	    {
	      printf ("ERROR, an = %d, bn = %d, rn = %d\n",
		      (int) an, (int) bn, (int) rn);
	      printf ("a: "); mpn_dump (ap, an);
	      printf ("b: "); mpn_dump (bp, bn);
	      printf ("r:   "); mpn_dump (rq, rn);
	      printf ("ref: "); mpn_dump (refq, rn);
	      abort();
	    }
#endif
	}
    }

  //TMP_FREE;
  //tests_end ();
  return 0;
}

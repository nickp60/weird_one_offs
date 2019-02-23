data {
  int<lower=0> N;                      // total number of datapoints
  int<lower=0> Npref;                  // types of preeferences
  vector[N] y;                         // taster's rating
  int <lower=1, upper=2> pref[N];      // preferences, coded 1-2
  int<lower=1> Nperson;                // number of persons
  int<lower=1>  person[N];             // which person
  int<lower=0> Nwine;                  // number of wines
  int <lower=1> wine[N];               // which wine
  int<lower=0> Ntype;                  // number of wine types (red or white)
  int <lower=1, upper=2> type[N];      // which wine type
  int<lower=0> not_prefered[N];        // to hold 0 ir 1 if preference  matches wine type
}
parameters {
  vector[Nwine] m;                    // slope - effect of wine order (or time)
  vector[Nwine] b;                    // intercept - rating before time effect
  //vector[Ntype] not_my_fav;            // effect of whether a wine was prefered
  vector[Nperson] personal_bias;       // correction factor for a persons 
  real<lower=0> sigma;                 // measurement error
  real not_my_fav;
}
transformed parameters {
  vector[N] y_hat;                     // the *real* measured value, without measurement error
  for (n in 1:N) {
    y_hat[n] = ((m[wine[n]] * wine[n]) +  b[wine[n]]) + (not_prefered[n] * not_my_fav) + personal_bias[person[n]];
  }
}
model {
  personal_bias ~  normal(0, 2);
  not_my_fav ~ normal(0, 1);
  m ~ cauchy(-2, 2);
  b ~ cauchy(5, 1);
  y ~ normal(y_hat, sigma);               // fit with error
}

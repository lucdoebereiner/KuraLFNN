Server.default.options.blockSize = 64;
Server.default.reboot;
Server.default.volume.gui;

(
~analysisBus = Bus.audio(s, 1);
~inBus = Bus.audio(s, 1);
~parameters = [0, 0, 0, 0, 0, 0, 0];
~fft = Buffer.alloc(s, 4096)
)

(
~farben = Buffer.read(s, "/home/luc/Dropbox/test_audio/farben_tahoe.wav");

~techno = Buffer.read(s, "/home/luc/Dropbox/test_audio/techno.wav");

~radulescu = Buffer.read(s, "/home/luc/Dropbox/test_audio/radulescu.wav");

~cassandra = Buffer.read(s, "/home/luc/Dropbox/test_audio/cassandra.wav");

~schoenberg = Buffer.read(s, "/home/luc/Dropbox/test_audio/schoenberg.wav");
)


~e = Buffer.sendCollection(s, Env.perc.discretize, 1);

(
x = { arg w1 = 0.01, w2 = 0.0022, w3 = 0.073, k1 = -1.4, k2 = 0.1, k3 = -0.3, dur = 0.08, lagTime = 0.01, rndDev=0.001, lagPar = 0;
	var ph = LocalIn.ar(3, [0.1, 0.2, 0.3]);
	var ph1 = w1.lag2(lagPar) + (k1.lag2(lagPar) * ((ph[1] - ph[0]).sin + (ph[2] - ph[0]).sin) / 2);
	var ph2 = w2.lag2(lagPar) + (k2.lag2(lagPar) * ((ph[0] - ph[1]).sin + (ph[2] - ph[1]).sin) / 2);
	var ph3 = w3.lag2(lagPar) + (k3.lag2(lagPar) * ((ph[0] - ph[2]).sin + (ph[1] - ph[2]).sin) / 2);
	var newPh = (ph + [ph1, ph2,ph3]).mod(2*pi) + (LFNoise1.ar(10!3).range(-1 * rndDev.lag2(lagPar), rndDev.lag2(lagPar)));
	var trigger = (newPh < ph);
	var snd = SinOsc.ar(3000); //RLPF.ar(LFPulse.ar([100,230,530]), 400, 0.1);
	var amps = Trig.ar(trigger, 0.02).lag2ud(0.01, 0.01);
	//	var amps = Trig.ar(trigger, dur.lag2(lagPar)).lag2(lagTime.lag2(lagPar)).pow(2);
	//	var audio = GrainSin.ar(1, Trig.ar(trigger, 0.02), 0.02, 300, envbufnum: ~e.bufnum, mul: 0.6).sum.tanh;
	var audio = (snd * amps) * 0.5; //.tanh * 0.3;
	//	var audio = Splay.ar(Trig.ar(trigger, dur.lag2(lagPar)).lag2(lagTime.lag2(lagPar)) * snd);
	LocalOut.ar(newPh.mod(2*pi));
	Out.ar(0, audio.dup); //JPverb.ar(audio, t60: 2, damp: 0.2, size: 2, earlyDiff: 0.01) + (audio * 0.3));
	Out.ar(~analysisBus.index, audio);
}.play;

~smplInc = {arg freq;
	(freq*(2*pi))/48000
};

~rndPars = {
	~parameters[0] = ~smplInc.(0.1.exprand(2)) * 2 * 64;
	~parameters[1] = ~smplInc.(0.1.exprand(2)) * 2 * 64;
	~parameters[2] = ~smplInc.(0.1.exprand(2)) * 2 * 64;
	~parameters[3] = 0.0.gauss(0.8);
	~parameters[4] = 0.0.gauss(0.8);
	~parameters[5] = 0.0.gauss(0.8);
	//	~parameters[6] = 0.02;//0.005.exprand(0.03);
	//~parameters[7] = 0.01;//0.005.exprand(0.1);
	~parameters[6] = 0.0001.exprand(0.25);
	//	[0, 0.0001, 0.00025, 0.0005, 0.001, 0.01].choose;
	x.set(\w1, ~parameters[0],
		\w2, ~parameters[1],
		\w3, ~parameters[2],
		\k1, ~parameters[3],
		\k2, ~parameters[4],
		\k3, ~parameters[5],
		\dur, 0.02,
		\lagTime, 0.01,
		\rndDev, ~parameters[6],
	);
};
)

~rndPars.value();


(
~analysis = { arg prediction = 1;
	var in = In.ar(~analysisBus);
	//	var in = PlayBuf.ar(2, ~schoenberg.bufnum, loop: 1)[0];
	//	var in = PlayBuf.ar(2, ~techno.bufnum, loop: 1)[0];
	var env = A2K.kr(RMS.ar(in, 20)).poll;
	var chain = FFT(~fft.bufnum, env, 1, 1);
	Out.ar(0, in);
}.play;

Routine({
    inf.do{arg i;
        ~fft.getToFloatArray(action: { arg array;
            var z, x, m;
            z = array.clump(2).flop;
            // Initially data is in complex form
            z = [Signal.newFrom(z[0]), Signal.newFrom(z[1])];
            x = Complex(z[0], z[1]);
			~mag = x.magnitude.drop(1).keep(200);
		});
		1.wait;		
}}).play;
)


~mag


~mag.plot




	
// calc

	

{ ControlRate.ir.poll }.play;

750/2/2

1/(750/4096)
750/4096

0.18 - 30

(1 * 750) / 4096

(250 * 750) / 4096

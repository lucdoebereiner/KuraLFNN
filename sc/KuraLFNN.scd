Server.default.options.blockSize = 64;
Server.default.reboot;
Server.default.volume.gui;
//Server.default.options.numOutputBusChannels = 4;

(
~analysisBus = Bus.audio(s, 1);
~inBus = Bus.audio(s, 1);
~parameters = [0, 0, 0, 0, 0, 0, 0];
~fft = Buffer.alloc(s, 4096)
)

(
// files for testing
~psappha = Buffer.read(s, "/home/luc/Dropbox/test_audio/psappha.wav");

~farben = Buffer.read(s, "/home/luc/Dropbox/test_audio/farben_tahoe.wav");

~techno = Buffer.read(s, "/home/luc/Dropbox/test_audio/techno.wav");

~radulescu = Buffer.read(s, "/home/luc/Dropbox/test_audio/radulescu.wav");

~cassandra = Buffer.read(s, "/home/luc/Dropbox/test_audio/cassandra.wav");

~schoenberg = Buffer.read(s, "/home/luc/Dropbox/test_audio/schoenberg.wav");
)


(
// Network of three Kuramoto oscillators
x = { arg w1 = 0.01, w2 = 0.0022, w3 = 0.073, k1 = -1.4, k2 = 0.1, k3 = -0.3, dur = 0.08, lagTime = 0.01, rndDev=0.001, lagPar = 0;
	var ph = LocalIn.ar(3, [0.1, 0.2, 0.3]);
	var ph1 = w1.lag2(lagPar) + (k1.lag2(lagPar) * ((ph[1] - ph[0]).sin + (ph[2] - ph[0]).sin) / 2);
	var ph2 = w2.lag2(lagPar) + (k2.lag2(lagPar) * ((ph[0] - ph[1]).sin + (ph[2] - ph[1]).sin) / 2);
	var ph3 = w3.lag2(lagPar) + (k3.lag2(lagPar) * ((ph[0] - ph[2]).sin + (ph[1] - ph[2]).sin) / 2);
	var newPh = (ph + [ph1, ph2,ph3]).mod(2*pi) + (LFNoise1.ar(10!3).range(-1 * rndDev.lag2(lagPar), rndDev.lag2(lagPar)));
	var trigger = (newPh < ph);
	var snd = SinOsc.ar([1511.14,952.2,600]); 
	var amps = Trig.ar(trigger, 0.03).lag2ud(0.01, 0.05);
	var audio = (snd * amps).sum * 0.3; 
	LocalOut.ar(newPh.mod(2*pi));
	Out.ar(2, audio.dup); 
	Out.ar(~analysisBus.index, audio);
}.play;

~smplInc = {arg freq;
	(freq*(2*pi))/48000
};

// generate random parameters
~rndPars = {
	// ~parameters[0] = ~smplInc.(0.1.exprand(3)) * 64;
	// ~parameters[1] = ~smplInc.(0.1.exprand(3)) * 64;
	// ~parameters[2] = ~smplInc.(0.1.exprand(3)) * 64;
	~parameters[0] = ~smplInc.(0.3.exprand(3)) * 64;
	~parameters[1] = ~smplInc.(0.3.exprand(3)) * 64;
	~parameters[2] = ~smplInc.(0.3.exprand(3)) * 64;

	// ~parameters[3] = 0.00002.exprand(1.7) * [-1,1,1].choose;
	// ~parameters[4] = 0.00002.exprand(1.7) * [-1,1,1].choose;
	// ~parameters[5] = 0.00002.exprand(1.7) * [-1,1,1].choose;

	~parameters[3] = 0.00002.exprand(0.5);// * [-1,1,1].choose;
	~parameters[4] = 0.00002.exprand(0.5);// * [-1,1,1].choose;
	~parameters[5] = 0.00002.exprand(0.5);//* [-1,1,1].choose;


	// ~parameters[3] = 0.0.gauss(2);
	// ~parameters[4] = 0.0.gauss(2);
	// ~parameters[5] = 0.0.gauss(2);
	//	~parameters[6] = 0.02;//0.005.exprand(0.03);
	//~parameters[7] = 0.01;//0.005.exprand(0.1);
	~parameters[6] = 0.0001.exprand(0.2);
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


(
// Create Rhythm Spectrum
~analysis = { arg prediction = 1;
	var in = In.ar(~analysisBus);
	//	var in = PlayBuf.ar(2, ~psappha.bufnum, loop: 1)[0];
	//	var in = PlayBuf.ar(2, ~schoenberg.bufnum, loop: 1)[0];
	//	var in = PlayBuf.ar(2, ~cassandra.bufnum, loop: 1)[0];
	//	var in = PlayBuf.ar(2, ~farben.bufnum, loop: 1)[0];
	var env = A2K.kr(RMS.ar(in, 20));
	var chain = FFT(~fft.bufnum, env, 1, 1);
	Out.ar(0, in);
}.play;
)

//~analysis.free

(
// Extract and normalize magnitudes
Routine({
    inf.do{arg i;
        ~fft.getToFloatArray(action: { arg array;
            var z, x, m;
            z = array.clump(2).flop;
            // Initially data is in complex form
            z = [Signal.newFrom(z[0]), Signal.newFrom(z[1])];
            x = Complex(z[0], z[1]);
			~mag = x.magnitude.drop(2).keep(200).normalizeSum;
		});
		1.wait;		
}}).play;
)


~mag.plot

// Training

// python server
// python main_tf.py -s 200 -i 200 -o 7 -d 4 -lr 1 -b 32

~nn = NetAddr.new("127.0.0.1", 1337);

(
~addPoint = {
	var inAndOut = ~mag ++ ~parameters;
	inAndOut.postln;
	~nn.sendMsg("/nn/point", *inAndOut)
}
)


(
~addTask = Task({
	inf.do({ arg i;
		i.postln;
		~rndPars.value();
		7.wait;
		~addPoint.();
		2.wait;
	});
});
)

// keep adding settings
~addTask.play

// save collected training data
~nn.sendMsg("/savedata", "rhythmkuradata3.json");

// save model to disk
~nn.sendMsg("/save", "rhythmkuramodel3");


~loss = [];

l = OSCFunc({ arg msg; [msg[1], msg[2].round(0.00001)].postln; ~loss = ~loss.add(msg[2])}, '/loss');
l.free;

// train
~nn.sendMsg("/nn/train", 1000);

~loss.plot

// print losses
~loss.do({|e| e.post; ", ".post})

// predict


(
~predict = {
	~nn.sendMsg("/nn/pred", *~mag)
}
)

(
p = OSCFunc({ arg msg; ~parameters = msg[1..].postln;
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
}, '/pred');
)

// predict once
~predict.()

// keep predicting
Task{ inf.do({ ~predict.(); 2.wait; }) }.play


// Testing and calculations

{ ControlRate.ir.poll }.play;

750/2/2

1/(750/4096)
750/4096

0.18 - 30

(1 * 750) / 4096

(250 * 750) / 4096
